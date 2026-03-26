import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/router/router_provider.dart';
import '../../cloud/providers/cloud_provider.dart';
import '../../device/providers/device_provider.dart';
import '../models/lan_device.dart';
import '../services/lan_discovery_service.dart';
import '../services/lan_http_server.dart';
import '../services/lan_transfer_service.dart';

part 'lan_provider.g.dart';

@Riverpod(keepAlive: true)
class LanManager extends _$LanManager {
  LanDiscoveryService? _discovery;
  LanHttpServer? _server;
  StreamSubscription? _sub;
  Timer? _cleanupTimer;

  @override
  List<LanDevice> build() {
    _init();
    ref.onDispose(_dispose);
    return [];
  }

  Future<void> _init() async {
    final deviceId = ref.read(deviceIdProvider) ?? 'unknown_id';
    final deviceName = ref.read(deviceNameProvider);
    final storageDir = ref.read(fileServiceProvider).storageDir;

    // Start HTTP Server
    _server = LanHttpServer(
      saveDirectory: storageDir.isNotEmpty ? storageDir : Directory.systemTemp.path,
      deviceId: deviceId,
      onReceiveRequest: _handleReceiveRequest,
      onProgress: (fileName, progress) {
        // TODO: show progress in UI
      },
      onComplete: (fileName) {
        // Refresh cloud list if needed
        ref.read(cloudFileListProvider.notifier).refresh();
      },
      onError: (fileName, error) {
        debugPrint('Receive error: $error');
      },
    );

    final port = await _server!.start();

    // Start Discovery
    _discovery = LanDiscoveryService(
      deviceId: deviceId,
      deviceName: deviceName,
      httpPort: port,
      os: Platform.operatingSystem,
    );

    _sub = _discovery!.onDeviceFound.listen((device) {
      final current = List<LanDevice>.from(state);
      final index = current.indexWhere((d) => d.deviceId == device.deviceId);
      if (index >= 0) {
        current[index] = device;
      } else {
        current.add(device);
      }
      state = current;
    });

    await _discovery!.start();

    // Cleanup stale devices
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final filtered = state.where((d) => now - d.lastSeen < 10000).toList();
      if (filtered.length != state.length) {
        state = filtered;
      }
    });
  }

  void _dispose() {
    _sub?.cancel();
    _cleanupTimer?.cancel();
    _discovery?.stop();
    _server?.stop();
  }

  Future<bool> _handleReceiveRequest(String fileName, String senderName) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('接收文件'),
        content: Text('来自 [$senderName] 的文件:\n$fileName\n\n是否接收？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('拒绝'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('接收'),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> sendFile(LanDevice target, String filePath) async {
    final senderName = ref.read(deviceNameProvider);
    final transfer = LanTransferService();
    
    // Check if alive
    final isAlive = await transfer.ping(target.ip, target.port);
    if (!isAlive) {
      throw Exception('设备无响应');
    }

    await transfer.sendFile(
      ip: target.ip,
      port: target.port,
      filePath: filePath,
      senderName: senderName,
      onProgress: (p) {
        // TODO: show progress
      },
    );
  }
}
