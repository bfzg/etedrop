import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum DeskflowMode { server, client }

enum DeskflowStatus { stopped, starting, running, failed }

class DeskflowConfig {
  const DeskflowConfig({
    required this.mode,
    this.remoteHost,
    this.port = 24800,
    this.clipboard = true,
    this.screenName = 'etedrop',
  });

  final DeskflowMode mode;
  final String? remoteHost;
  final int port;
  final bool clipboard;
  final String screenName;

  String toConfigText() {
    final out = StringBuffer('[core]\nport=$port\n');
    out.writeln('computerName=$screenName');
    out.writeln('[server]\nenableClipboard=${clipboard ? 'true' : 'false'}');
    if (mode == DeskflowMode.client) {
      out.writeln('[client]\nremoteHost=${remoteHost ?? ''}');
    }
    return out.toString();
  }
}

class DeskflowService extends ChangeNotifier {
  Process? _process;
  StreamSubscription<String>? _stdout;
  StreamSubscription<String>? _stderr;
  DeskflowStatus _status = DeskflowStatus.stopped;
  String? _lastError;
  final List<String> _logs = <String>[];

  DeskflowStatus get status => _status;
  String? get lastError => _lastError;
  List<String> get logs => List.unmodifiable(_logs);
  bool get isRunning => _process != null;

  Future<void> openAccessibilitySettings() async {
    if (!Platform.isMacOS) return;
    await Process.run('open', [
      'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility',
    ]);
  }

  Future<List<String>> localIpv4Addresses() async {
    final values = <String>[];
    for (final interface in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    )) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) values.add(address.address);
      }
    }
    return values.toSet().toList();
  }

  Future<List<String>> scanLocalNetwork({int port = 24800}) async {
    final found = <String>[];
    for (final address in await localIpv4Addresses()) {
      final parts = address.split('.');
      if (parts.length != 4) continue;
      final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
      await Future.wait(
        List.generate(254, (index) {
          final host = '$prefix.${index + 1}';
          if (host == address) return Future<void>.value();
          return Socket.connect(
                host,
                port,
                timeout: const Duration(milliseconds: 120),
              )
              .then((socket) {
                found.add(host);
                socket.destroy();
              })
              .catchError((_) {});
        }),
      );
    }
    return found.toSet().toList();
  }

  Future<void> start(DeskflowConfig config) async {
    if (_process != null) return;
    _setStatus(DeskflowStatus.starting);
    _lastError = null;
    try {
      final executable = await _resolveExecutable();
      final localScreenName = await _computerName();
      final dir = await Directory.systemTemp.createTemp('etedrop-deskflow-');
      final configFile = File(
        '${dir.path}${Platform.pathSeparator}Deskflow.conf',
      );
      await configFile.writeAsString(
        config.toConfigText().replaceFirst(
          'computerName=${config.screenName}',
          'computerName=$localScreenName',
        ),
      );
      if (config.mode == DeskflowMode.server) {
        final serverFile = File(
          '${dir.path}${Platform.pathSeparator}deskflow-server.conf',
        );
        // The server config uses screen names, not IP addresses. The IP is
        // only used by the client connection settings.
        const remote = 'client';
        await serverFile.writeAsString(
          'section: screens\n\t$localScreenName:\n\t$remote:\nend\nsection: links\n\t$localScreenName:\n\t\tright = $remote\n\t$remote:\n\t\tleft = $localScreenName\nend\nsection: options\n\tclipboardSharing = ${config.clipboard ? 'true' : 'false'}\nend\n',
        );
        await configFile.writeAsString(
          '[core]\ncomputerName=$localScreenName\nport=${config.port}\n[server]\nexternalConfig=true\nexternalConfigFile=${serverFile.path}\n',
        );
      }
      // Deskflow expects the mode as a positional argument and -s for settings.
      final args = <String>[
        config.mode == DeskflowMode.server ? 'server' : 'client',
        '-s',
        configFile.path,
      ];
      _process = await Process.start(executable, args, runInShell: false);
      _stdout = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_appendLog);
      _stderr = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_appendLog);
      _process!.exitCode.then((code) {
        _appendLog('Deskflow exited with code $code');
        if (code != 0) {
          _lastError = 'Deskflow 启动失败（退出码 $code），请查看下方日志';
        }
        _process = null;
        if (_status != DeskflowStatus.failed) {
          _setStatus(DeskflowStatus.stopped);
        }
      });
      _setStatus(DeskflowStatus.running);
    } catch (e) {
      _lastError = e.toString();
      _appendLog(_lastError!);
      _setStatus(DeskflowStatus.failed);
    }
  }

  Future<String> _computerName() async {
    String name = 'etedrop-mac';
    if (Platform.isMacOS) {
      final result = await Process.run('scutil', ['--get', 'LocalHostName']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        name = result.stdout.toString().trim();
      }
    } else if (Platform.isWindows) {
      name = Platform.environment['COMPUTERNAME'] ?? name;
    }
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final looksLikeIp = RegExp(r'^\d+(?:_\d+){3}$').hasMatch(cleaned);
    return looksLikeIp || cleaned.isEmpty ? 'etedrop-mac' : cleaned;
  }

  Future<void> stop() async {
    final process = _process;
    if (process == null) return;
    process.kill();
    await process.exitCode.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    await _stdout?.cancel();
    await _stderr?.cancel();
    _process = null;
    _setStatus(DeskflowStatus.stopped);
  }

  Future<String> _resolveExecutable() async {
    if (!Platform.isWindows && !Platform.isMacOS) {
      throw UnsupportedError(
        'Deskflow integration supports Windows and macOS only',
      );
    }
    final base = File(Platform.resolvedExecutable).parent.path;
    final name = Platform.isWindows ? 'deskflow-core.exe' : 'deskflow-core';
    final candidates = <String>[
      '$base${Platform.pathSeparator}$name',
      '$base${Platform.pathSeparator}deskflow${Platform.pathSeparator}$name',
      '${Directory.current.path}${Platform.pathSeparator}assets${Platform.pathSeparator}native${Platform.pathSeparator}deskflow${Platform.pathSeparator}windows${Platform.pathSeparator}$name',
      '${Directory.current.path}${Platform.pathSeparator}assets${Platform.pathSeparator}native${Platform.pathSeparator}deskflow${Platform.pathSeparator}macos${Platform.pathSeparator}Deskflow.app${Platform.pathSeparator}Contents${Platform.pathSeparator}MacOS${Platform.pathSeparator}$name',
    ];
    for (final path in candidates) {
      if (await File(path).exists()) return path;
    }
    throw FileSystemException(
      'Deskflow core executable was not found',
      candidates.first,
    );
  }

  void _appendLog(String value) {
    if (value.trim().isEmpty) return;
    if (value.contains('assistive devices does not trust this process')) {
      _lastError = 'macOS 需要授予辅助功能权限';
      unawaited(openAccessibilitySettings());
    }
    _logs.add(value);
    if (_logs.length > 300) _logs.removeAt(0);
    notifyListeners();
  }

  void _setStatus(DeskflowStatus value) {
    _status = value;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}

final deskflowServiceProvider = Provider<DeskflowService>((ref) {
  final service = DeskflowService();
  ref.onDispose(service.dispose);
  return service;
});
