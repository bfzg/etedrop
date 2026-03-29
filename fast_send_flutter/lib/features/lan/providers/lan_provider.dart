import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../cloud/providers/cloud_provider.dart';
import '../../device/providers/device_provider.dart';
import '../../message/models/transfer_message.dart';
import '../../message/providers/message_provider.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/notification_service.dart';
import '../models/lan_device.dart';
import '../models/lan_share_payload.dart';
import '../services/lan_discovery_service.dart';
import '../services/lan_http_context.dart';
import '../services/lan_http_server.dart';
import '../services/lan_network_utils.dart';
import '../services/lan_transfer_service.dart';

part 'lan_provider.g.dart';

/// 超过该时间未收到发现广播则视为离线（仍保留在列表，仅 `isOnline: false`）。
/// 与发现层约 3s 心跳对齐：约 8 个周期 + 余量，并留 UDP 丢包容忍。
const int _lanDeviceStaleMs = 24000;

/// 超过该时间无任何发现包则从列表与本地缓存移除，避免无限增长。
const int _lanDeviceForgetMs = 14 * 24 * 60 * 60 * 1000;

bool _lanDeviceListEquals(List<LanDevice> a, List<LanDevice> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _OutgoingShare {
  final String shareId;
  final List<String> filePaths;
  final List<LanDevice> targets;
  final Timer expiryTimer;
  bool cancelled = false;

  _OutgoingShare({
    required this.shareId,
    required this.filePaths,
    required this.targets,
    required this.expiryTimer,
  });
}

@Riverpod(keepAlive: true)
class LanManager extends _$LanManager {
  LanDiscoveryService? _discovery;
  LanHttpServer? _server;
  int _listenPort = 0;
  StreamSubscription? _sub;
  StreamSubscription<String>? _goneSub;
  Timer? _cleanupTimer;
  Timer? _persistDebounce;

  final Map<String, Completer<bool>> _pendingDecisions = {};
  final Map<String, _OutgoingShare> _outgoingShares = {};
  /// 多设备同时接受时，每个上传任务结束递减；归零且任一批成功则收尾会话
  final Map<String, int> _outboundUploadRefCount = {};
  final Map<String, bool> _outboundHadSuccess = {};

  @override
  List<LanDevice> build() {
    _init();
    ref.onDispose(_dispose);
    return [];
  }

  int get localHttpPort => _listenPort;

  Future<void> _init() async {
    await ref.read(deviceConfigReadyProvider.future);

    final manager = ref.read(deviceManagerProvider);
    final config = manager.config ?? await manager.loadConfig();
    final deviceId = config.deviceId;
    final deviceName = config.deviceName;
    final deviceAvatar = config.avatar;
    final cloudDir = ref.read(fileServiceProvider).storageDir;
    final downloadDir = await ref.read(downloadDirProvider.future);

    final remembered = await _loadRememberedLanDevices();

    _server = LanHttpServer(
      saveDirectory: downloadDir.isNotEmpty
          ? downloadDir
          : (cloudDir.isNotEmpty ? cloudDir : Directory.systemTemp.path),
      deviceId: deviceId,
      onShareOffer: _onIncomingShareOffer,
      onShareAccept: _onShareAcceptFromReceiver,
      onShareCancel: _onIncomingShareCancel,
      onReceiveUpload: _onReceiveUploadPermission,
      onProgress: _onReceiveUploadProgress,
      onComplete: _onReceiveUploadComplete,
      onError: _onReceiveUploadError,
    );

    _listenPort = await _server!.start();

    _discovery = LanDiscoveryService(
      deviceId: deviceId,
      deviceName: deviceName,
      httpPort: _listenPort,
      os: Platform.operatingSystem,
      avatar: deviceAvatar,
    );

    ref.listen<String>(deviceNameProvider, (prev, next) {
      _discovery?.updateLocalInfo(deviceName: next);
    });
    ref.listen<int>(deviceAvatarProvider, (prev, next) {
      _discovery?.updateLocalInfo(avatar: next);
    });

    if (remembered.isNotEmpty) {
      state = remembered;
    }

    _sub = _discovery!.onDeviceFound.listen((device) {
      final online = device.copyWith(isOnline: true);
      final current = List<LanDevice>.from(state);
      final index = current.indexWhere((d) => d.deviceId == online.deviceId);
      if (index >= 0) {
        current[index] = online;
      } else {
        current.add(online);
      }
      state = current;
      _schedulePersistRememberedDevices();
    });

    _goneSub = _discovery!.onDeviceGone.listen((id) {
      final next = state
          .map(
            (d) =>
                d.deviceId == id ? d.copyWith(isOnline: false) : d,
          )
          .toList();
      if (!_lanDeviceListEquals(state, next)) {
        state = next;
        _schedulePersistRememberedDevices();
      }
    });

    await _discovery!.start();

    _cleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _applyStaleForgetAndOffline();
    });

    ref.listen(messageListProvider, (prev, next) {
      _checkPendingDecisions(next);
    });
  }

  Future<List<LanDevice>> _loadRememberedLanDevices() async {
    try {
      final raw = LocalStorageService.instance
          .get<String>(StorageKeys.lanRememberedDevices);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (e) => LanDevice.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ).copyWith(isOnline: false),
          )
          .toList();
    } catch (e) {
      debugPrint('LAN remembered load: $e');
      return [];
    }
  }

  void _schedulePersistRememberedDevices() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_flushPersistRememberedDevices());
    });
  }

  Future<void> _flushPersistRememberedDevices() async {
    try {
      final encoded = jsonEncode(state.map((d) => d.toJson()).toList());
      await LocalStorageService.instance
          .set<String>(StorageKeys.lanRememberedDevices, encoded);
    } catch (e) {
      debugPrint('LAN remembered persist: $e');
    }
  }

  void _applyStaleForgetAndOffline() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final next = <LanDevice>[];
    for (final d in state) {
      if (now - d.lastSeen > _lanDeviceForgetMs) continue;
      final stale = now - d.lastSeen >= _lanDeviceStaleMs;
      if (stale && d.isOnline) {
        next.add(d.copyWith(isOnline: false));
      } else {
        next.add(d);
      }
    }
    if (!_lanDeviceListEquals(state, next)) {
      state = next;
      _schedulePersistRememberedDevices();
    }
  }

  void _dispose() {
    _persistDebounce?.cancel();
    unawaited(_flushPersistRememberedDevices());
    _sub?.cancel();
    _goneSub?.cancel();
    _cleanupTimer?.cancel();
    _discovery?.stop();
    _server?.stop();
    for (final c in _pendingDecisions.values) {
      if (!c.isCompleted) c.complete(false);
    }
    _pendingDecisions.clear();
    for (final s in _outgoingShares.values) {
      s.expiryTimer.cancel();
    }
    _outgoingShares.clear();
    _outboundUploadRefCount.clear();
    _outboundHadSuccess.clear();
  }

  // —— 接收：分享邀约 —— //
  Future<void> _onIncomingShareOffer(LanShareOfferPayload offer) async {
    if (DateTime.now().millisecondsSinceEpoch > offer.expiresAtMs) return;

    final files = offer.files.map((e) => e.toJson()).toList();
    ref.read(messageListProvider.notifier).addIncomingBatchOffer(
          shareId: offer.shareId,
          senderName: offer.senderName,
          senderDeviceId: offer.senderDeviceId,
          senderAvatar: offer.senderAvatar,
          files: files,
          senderHttpHost: offer.senderHost,
          senderHttpPort: offer.senderPort,
        );

    final waitMs = offer.expiresAtMs - DateTime.now().millisecondsSinceEpoch;
    if (waitMs > 0) {
      Future.delayed(Duration(milliseconds: waitMs), () {
        final m = ref
            .read(messageListProvider.notifier)
            .findIncomingByShareId(offer.shareId);
        if (m != null && m.status == TransferMessageStatus.pending) {
          ref.read(messageListProvider.notifier).expireIncomingByShareId(
                offer.shareId,
                reason: '等待超时',
              );
        }
      });
    }

    final summary = files.length == 1
        ? (files.first['name'] as String? ?? '文件')
        : '${files.length} 个文件';
    NotificationService.instance.showIncomingTransfer(
      senderName: offer.senderName,
      fileName: summary,
    );
  }

  Future<void> _onIncomingShareCancel(LanShareCancelPayload cancel) async {
    ref.read(messageListProvider.notifier).rejectByShareId(
          cancel.shareId,
          reason: '发送方已取消',
        );
  }

  /// 接收方点击接受/拒绝后，回调发送方 HTTP
  Future<void> receiverRespondToShare(TransferMessage msg, bool accepted) async {
    if (msg.shareId == null ||
        msg.senderHttpHost == null ||
        msg.senderHttpPort == null) {
      throw Exception('无效的分享消息');
    }
    final myId = ref.read(deviceIdProvider) ?? '';
    final transfer = LanTransferService();
    await transfer.postShareAccept(
      senderHost: msg.senderHttpHost!,
      senderPort: msg.senderHttpPort!,
      payload: LanShareAcceptPayload(
        shareId: msg.shareId!,
        receiverDeviceId: myId,
        accepted: accepted,
      ),
    );
  }

  // —— 发送方：接收端回调「已接受」后开始推流 —— //
  Future<void> _onShareAcceptFromReceiver(LanShareAcceptPayload payload) async {
    final session = _outgoingShares[payload.shareId];
    if (session == null || session.cancelled) return;

    if (!payload.accepted) return;

    LanDevice? device;
    for (final d in session.targets) {
      if (d.deviceId == payload.receiverDeviceId) {
        device = d;
        break;
      }
    }
    if (device == null) return;

    _outboundUploadRefCount[payload.shareId] =
        (_outboundUploadRefCount[payload.shareId] ?? 0) + 1;
    ref
        .read(messageListProvider.notifier)
        .markOutgoingShareReceivingByShareId(payload.shareId);
    unawaited(_uploadBatchToDevice(device, session));
  }

  void _onOutboundUploadFinished(String shareId, bool batchOk) {
    if (batchOk) {
      _outboundHadSuccess[shareId] = true;
    }
    final next = (_outboundUploadRefCount[shareId] ?? 1) - 1;
    if (next <= 0) {
      _outboundUploadRefCount.remove(shareId);
      final anyOk = _outboundHadSuccess.remove(shareId) == true;
      if (anyOk) {
        _finalizeOutboundShareDelivery(shareId);
      }
    } else {
      _outboundUploadRefCount[shareId] = next;
    }
  }

  void _finalizeOutboundShareDelivery(String shareId) {
    final session = _outgoingShares.remove(shareId);
    if (session != null && !session.cancelled) {
      session.cancelled = true;
      session.expiryTimer.cancel();
    }
    ref
        .read(messageListProvider.notifier)
        .markOutgoingShareCompletedByShareId(shareId);
  }

  Future<void> _uploadBatchToDevice(
    LanDevice device,
    _OutgoingShare session,
  ) async {
    var batchOk = false;
    try {
      final transfer = LanTransferService();
      final senderName = ref.read(deviceNameProvider);
      final senderAvatar = ref.read(deviceAvatarProvider);
      final senderDeviceId = ref.read(deviceIdProvider) ?? '';

      final isAlive = await transfer.ping(device.ip, device.port);
      if (!isAlive) return;

      var totalBytes = 0;
      for (final path in session.filePaths) {
        final f = File(path);
        if (await f.exists()) {
          totalBytes += await f.length();
        }
      }
      final n = session.filePaths.length;

      var expected = 0;
      var uploaded = 0;
      for (var i = 0; i < n; i++) {
        final path = session.filePaths[i];
        final f = File(path);
        if (!await f.exists()) continue;
        expected++;
        final size = await f.length();
        try {
          await transfer.sendFileStream(
            ip: device.ip,
            port: device.port,
            fileStream: f.openRead(),
            fileName: p.basename(path),
            fileSize: size,
            senderName: senderName,
            senderAvatar: senderAvatar,
            senderDeviceId: senderDeviceId,
            shareId: session.shareId,
            fileIndex: i,
            fileCount: n,
            batchTotalBytes: totalBytes,
            onProgress: (_) {},
          );
          uploaded++;
        } catch (e) {
          debugPrint('Upload failed: $e');
        }
      }
      batchOk = expected > 0 && uploaded == expected;
    } finally {
      _onOutboundUploadFinished(session.shareId, batchOk);
    }
  }

  /// 发起批量分享：先发邀约，对端接受后再按文件顺序流式上传（多设备可并行）
  /// 返回 shareId，供展示「分享链接」与取消
  Future<String> startBatchShare({
    required List<String> absoluteFilePaths,
    required List<String> targetDeviceIds,
  }) async {
    if (absoluteFilePaths.isEmpty) {
      throw Exception('请选择至少一个文件');
    }
    if (targetDeviceIds.isEmpty) {
      throw Exception('请选择至少一台设备');
    }
    if (_listenPort == 0) {
      throw Exception('本地服务未就绪');
    }

    final manager = ref.read(deviceManagerProvider);
    final config = manager.config ?? await manager.loadConfig();
    final senderDeviceId = config.deviceId;
    final senderName = config.deviceName;
    final senderAvatar = config.avatar;

    final host = await getLanIPv4() ?? '127.0.0.1';
    final shareId = const Uuid().v4();
    final expiresAt =
        DateTime.now().add(const Duration(minutes: 2)).millisecondsSinceEpoch;

    final files = <LanShareFileMeta>[];
    for (final path in absoluteFilePaths) {
      final f = File(path);
      if (!await f.exists()) continue;
      files.add(
        LanShareFileMeta(
          name: p.basename(path),
          size: await f.length(),
        ),
      );
    }
    if (files.isEmpty) throw Exception('无法读取所选文件');

    final targets = state
        .where(
          (d) => targetDeviceIds.contains(d.deviceId) && d.isOnline,
        )
        .toList();
    if (targets.isEmpty) {
      throw Exception('所选设备不在线或已离线，请等待设备上线后再试');
    }

    final payload = LanShareOfferPayload(
      shareId: shareId,
      senderDeviceId: senderDeviceId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderHost: host,
      senderPort: _listenPort,
      files: files,
      expiresAtMs: expiresAt,
    );

    final transfer = LanTransferService();
    for (final d in targets) {
      final ok = await transfer.ping(d.ip, d.port);
      if (!ok) continue;
      await transfer.postShareOffer(ip: d.ip, port: d.port, payload: payload);
    }

    final timer = Timer(const Duration(minutes: 2), () {
      cancelOutgoingShare(shareId);
    });

    _outgoingShares[shareId] = _OutgoingShare(
      shareId: shareId,
      filePaths: List<String>.from(absoluteFilePaths),
      targets: targets,
      expiryTimer: timer,
    );

    final fileMaps = files.map((e) => e.toJson()).toList();
    ref.read(messageListProvider.notifier).addOutgoingBatchShare(
          shareId: shareId,
          absoluteFilePaths: List<String>.from(absoluteFilePaths),
          targetDeviceIds: targets.map((d) => d.deviceId).toList(),
          senderName: senderName,
          senderDeviceId: senderDeviceId,
          senderAvatar: senderAvatar,
          files: fileMaps,
        );
    return shareId;
  }

  void cancelOutgoingShare(String shareId, {bool userCancelled = false}) {
    final session = _outgoingShares.remove(shareId);
    if (session != null && !session.cancelled) {
      session.cancelled = true;
      session.expiryTimer.cancel();

      final transfer = LanTransferService();
      final cancel = LanShareCancelPayload(shareId: shareId);
      for (final d in session.targets) {
        unawaited(
          transfer.postShareCancel(ip: d.ip, port: d.port, payload: cancel),
        );
      }
    }

    ref.read(messageListProvider.notifier).expireOutgoingShareIfPending(
          shareId,
          reason: userCancelled ? '已取消' : '已超时',
        );
  }

  // —— 上传权限（旧版单文件直传 / 新版批量） —— //
  Future<bool> _onReceiveUploadPermission(LanUploadContext ctx) async {
    final sid = ctx.shareId;
    if (sid == null || sid.isEmpty) {
      return _legacyReceiveUpload(ctx);
    }

    final msg = ref.read(messageListProvider.notifier).findIncomingByShareId(sid);
    if (msg == null) return false;
    if (msg.status == TransferMessageStatus.pending) return false;
    if (msg.status == TransferMessageStatus.rejected) return false;
    if (msg.status == TransferMessageStatus.expired) return false;
    if (msg.status == TransferMessageStatus.accepted && ctx.fileIndex == 0) {
      ref
          .read(messageListProvider.notifier)
          .updateStatus(msg.id, TransferMessageStatus.receiving);
      return true;
    }
    if (msg.status == TransferMessageStatus.receiving) {
      return true;
    }
    return false;
  }

  Future<bool> _legacyReceiveUpload(LanUploadContext ctx) async {
    final msgNotifier = ref.read(messageListProvider.notifier);
    final msg = msgNotifier.addIncoming(
      fileName: ctx.fileName,
      fileSize: ctx.fileSize,
      senderName: ctx.senderName,
      senderDeviceId: ctx.senderDeviceId,
      senderAvatar: ctx.senderAvatar,
    );
    NotificationService.instance.showIncomingTransfer(
      senderName: ctx.senderName,
      fileName: ctx.fileName,
    );

    final completer = Completer<bool>();
    _pendingDecisions[msg.id] = completer;

    final accepted = await completer.future;
    _pendingDecisions.remove(msg.id);

    if (accepted) {
      msgNotifier.updateStatus(msg.id, TransferMessageStatus.receiving);
    }
    return accepted;
  }

  void _onReceiveUploadProgress(
    LanUploadContext ctx,
    double fileProgress,
    double batchProgress,
  ) {
    if (ctx.shareId != null && ctx.shareId!.isNotEmpty) {
      ref
          .read(messageListProvider.notifier)
          .updateProgressByShareId(ctx.shareId!, batchProgress);
    } else {
      final messages = ref.read(messageListProvider);
      final msg = messages.cast<TransferMessage?>().firstWhere(
            (m) =>
                m!.fileName == ctx.fileName &&
                m.status == TransferMessageStatus.receiving,
            orElse: () => null,
          );
      if (msg != null) {
        ref.read(messageListProvider.notifier).updateProgress(msg.id, batchProgress);
      }
    }
  }

  void _onReceiveUploadComplete(LanUploadContext ctx) {
    if (ctx.shareId != null && ctx.shareId!.isNotEmpty) {
      if (ctx.fileIndex == ctx.fileCount - 1) {
        final msg = ref
            .read(messageListProvider.notifier)
            .findIncomingByShareId(ctx.shareId!);
        if (msg != null) {
          ref.read(messageListProvider.notifier).markCompleted(msg.id);
          NotificationService.instance.showTransferCompleted(
            senderName: msg.senderName,
            fileName: msg.fileName,
          );
        }
      }
    } else {
      final messages = ref.read(messageListProvider);
      final msg = messages.cast<TransferMessage?>().firstWhere(
            (m) =>
                m!.fileName == ctx.fileName &&
                (m.status == TransferMessageStatus.receiving ||
                    m.status == TransferMessageStatus.accepted),
            orElse: () => null,
          );
      if (msg != null) {
        ref.read(messageListProvider.notifier).markCompleted(msg.id);
        NotificationService.instance.showTransferCompleted(
          senderName: msg.senderName,
          fileName: ctx.fileName,
        );
      }
    }
    ref.read(cloudFileListProvider.notifier).refresh();
  }

  void _onReceiveUploadError(LanUploadContext ctx, String error) {
    debugPrint('Receive error: $error');
    if (ctx.shareId != null && ctx.shareId!.isNotEmpty) {
      final msg = ref
          .read(messageListProvider.notifier)
          .findIncomingByShareId(ctx.shareId!);
      if (msg != null) {
        ref.read(messageListProvider.notifier).markFailed(msg.id, error);
      }
    } else {
      final messages = ref.read(messageListProvider);
      final msg = messages.cast<TransferMessage?>().firstWhere(
            (m) =>
                m!.fileName == ctx.fileName &&
                m.status == TransferMessageStatus.receiving,
            orElse: () => null,
          );
      if (msg != null) {
        ref.read(messageListProvider.notifier).markFailed(msg.id, error);
      }
    }
  }

  void _checkPendingDecisions(List<TransferMessage> messages) {
    for (final msg in messages) {
      final completer = _pendingDecisions[msg.id];
      if (completer == null || completer.isCompleted) continue;

      if (msg.status == TransferMessageStatus.accepted) {
        completer.complete(true);
      } else if (msg.status == TransferMessageStatus.rejected ||
          msg.status == TransferMessageStatus.expired) {
        completer.complete(false);
      }
    }
  }

  Future<void> sendFile(LanDevice target, String filePath) async {
    final senderName = ref.read(deviceNameProvider);
    final senderAvatar = ref.read(deviceAvatarProvider);
    final senderDeviceId = ref.read(deviceIdProvider) ?? '';
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
      senderAvatar: senderAvatar,
      senderDeviceId: senderDeviceId,
      onProgress: (p) {},
    );
  }

  Future<void> sendFileStream(
    LanDevice target, {
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
  }) async {
    final senderName = ref.read(deviceNameProvider);
    final senderAvatar = ref.read(deviceAvatarProvider);
    final senderDeviceId = ref.read(deviceIdProvider) ?? '';
    final transfer = LanTransferService();

    final isAlive = await transfer.ping(target.ip, target.port);
    if (!isAlive) {
      throw Exception('设备无响应');
    }

    await transfer.sendFileStream(
      ip: target.ip,
      port: target.port,
      fileStream: fileStream,
      fileName: fileName,
      fileSize: fileSize,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderDeviceId: senderDeviceId,
      onProgress: (p) {},
    );
  }
}
