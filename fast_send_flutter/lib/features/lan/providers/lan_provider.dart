import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../cloud/providers/cloud_provider.dart';
import '../../device/providers/device_provider.dart';
import '../../message/models/transfer_message.dart';
import '../../message/providers/message_provider.dart';
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

  /// 等待用户在消息页面对某条消息做出 接收/拒绝 决策的 completer
  final Map<String, Completer<bool>> _pendingDecisions = {};

  @override
  List<LanDevice> build() {
    _init();
    ref.onDispose(_dispose);
    return [];
  }

  Future<void> _init() async {
    final deviceId = ref.read(deviceIdProvider) ?? 'unknown_id';
    final deviceName = ref.read(deviceNameProvider);
    final deviceAvatar = ref.read(deviceAvatarProvider);
    final storageDir = ref.read(fileServiceProvider).storageDir;

    _server = LanHttpServer(
      saveDirectory: storageDir.isNotEmpty ? storageDir : Directory.systemTemp.path,
      deviceId: deviceId,
      onReceiveRequest: _handleReceiveRequest,
      onProgress: (fileName, progress) {
        // 更新对应消息的进度（通过 fileName 查找）
        final messages = ref.read(messageListProvider);
        final msg = messages.cast<TransferMessage?>().firstWhere(
              (m) => m!.fileName == fileName && m.status == TransferMessageStatus.receiving,
              orElse: () => null,
            );
        if (msg != null) {
          ref.read(messageListProvider.notifier).updateProgress(msg.id, progress);
        }
      },
      onComplete: (fileName) {
        final messages = ref.read(messageListProvider);
        final msg = messages.cast<TransferMessage?>().firstWhere(
              (m) =>
                  m!.fileName == fileName &&
                  (m.status == TransferMessageStatus.receiving ||
                      m.status == TransferMessageStatus.accepted),
              orElse: () => null,
            );
        if (msg != null) {
          ref.read(messageListProvider.notifier).markCompleted(msg.id);
        }
        ref.read(cloudFileListProvider.notifier).refresh();
      },
      onError: (fileName, error) {
        debugPrint('Receive error: $error');
        final messages = ref.read(messageListProvider);
        final msg = messages.cast<TransferMessage?>().firstWhere(
              (m) => m!.fileName == fileName && m.status == TransferMessageStatus.receiving,
              orElse: () => null,
            );
        if (msg != null) {
          ref.read(messageListProvider.notifier).markFailed(msg.id, error);
        }
      },
    );

    final port = await _server!.start();

    _discovery = LanDiscoveryService(
      deviceId: deviceId,
      deviceName: deviceName,
      httpPort: port,
      os: Platform.operatingSystem,
      avatar: deviceAvatar,
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

    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final filtered = state.where((d) => now - d.lastSeen < 10000).toList();
      if (filtered.length != state.length) {
        state = filtered;
      }
    });

    // 监听消息状态变化以响应用户在消息页面的操作
    ref.listen(messageListProvider, (prev, next) {
      _checkPendingDecisions(next);
    });
  }

  void _dispose() {
    _sub?.cancel();
    _cleanupTimer?.cancel();
    _discovery?.stop();
    _server?.stop();
    for (final c in _pendingDecisions.values) {
      if (!c.isCompleted) c.complete(false);
    }
    _pendingDecisions.clear();
  }

  Future<bool> _handleReceiveRequest(String fileName, String senderName) async {
    final msgNotifier = ref.read(messageListProvider.notifier);
    final msg = msgNotifier.addIncoming(
      fileName: fileName,
      fileSize: 0,
      senderName: senderName,
      senderDeviceId: '',
    );

    final completer = Completer<bool>();
    _pendingDecisions[msg.id] = completer;

    final accepted = await completer.future;
    _pendingDecisions.remove(msg.id);

    if (accepted) {
      ref.read(messageListProvider.notifier).updateStatus(
            msg.id,
            TransferMessageStatus.receiving,
          );
    }

    return accepted;
  }

  void _checkPendingDecisions(List<TransferMessage> messages) {
    for (final msg in messages) {
      final completer = _pendingDecisions[msg.id];
      if (completer == null || completer.isCompleted) continue;

      if (msg.status == TransferMessageStatus.accepted) {
        completer.complete(true);
      } else if (msg.status == TransferMessageStatus.rejected) {
        completer.complete(false);
      }
    }
  }

  Future<void> sendFile(LanDevice target, String filePath) async {
    final senderName = ref.read(deviceNameProvider);
    final transfer = LanTransferService();

    final isAlive = await transfer.ping(target.ip, target.port);
    if (!isAlive) {
      throw Exception('设备无响应');
    }

    await transfer.sendFile(
      ip: target.ip,
      port: target.port,
      filePath: filePath,
      senderName: senderName,
      onProgress: (p) {},
    );
  }
}
