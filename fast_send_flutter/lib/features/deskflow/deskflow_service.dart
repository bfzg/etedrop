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

  Future<void> start(DeskflowConfig config) async {
    if (_process != null) return;
    _setStatus(DeskflowStatus.starting);
    _lastError = null;
    try {
      final executable = await _resolveExecutable();
      final dir = await Directory.systemTemp.createTemp('etedrop-deskflow-');
      final configFile = File(
        '${dir.path}${Platform.pathSeparator}Deskflow.conf',
      );
      await configFile.writeAsString(config.toConfigText());
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
