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
import '../../../core/http/cancel_token.dart';
import '../../../core/utils/transfer_temp_cache.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/notification_service.dart';
import '../models/lan_device.dart';
import '../models/lan_share_payload.dart';
import '../services/lan_discovery_service.dart';
import '../services/lan_http_context.dart';
import '../services/lan_http_server.dart';
import '../services/lan_network_utils.dart';
import '../services/lan_transfer_service.dart';
import 'transfer_receive_speed_provider.dart';

part 'lan_provider.g.dart';

/// 超过该时间未收到发现广播则视为离线（仍保留在列表，仅 `isOnline: false`）。
/// 与发现层约 3s 心跳对齐：约 8 个周期 + 余量，并留 UDP 丢包容忍。
const int _lanDeviceStaleMs = 24000;

/// 超过该时间无任何发现包则从列表与本地缓存移除，避免无限增长。
const int _lanDeviceForgetMs = 14 * 24 * 60 * 60 * 1000;

/// 单文件在内层断点续传仍失败后，外层再试次数（网络闪断等）。
const int _lanUploadOuterRetries = 5;

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
  final LanCancelToken uploadCancelToken = LanCancelToken();
  bool cancelled = false;

  /// 发送成功后删除（粘贴图 / 临时 txt）；须在对方接受并完成上传后再删。
  final List<String> managedTempPathsToDeleteAfterDelivery;

  _OutgoingShare({
    required this.shareId,
    required this.filePaths,
    required this.targets,
    required this.expiryTimer,
    this.managedTempPathsToDeleteAfterDelivery = const [],
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
          .map((d) => d.deviceId == id ? d.copyWith(isOnline: false) : d)
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
      final raw = LocalStorageService.instance.get<String>(
        StorageKeys.lanRememberedDevices,
      );
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
      await LocalStorageService.instance.set<String>(
        StorageKeys.lanRememberedDevices,
        encoded,
      );
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
    ref
        .read(messageListProvider.notifier)
        .addIncomingBatchOffer(
          shareId: offer.shareId,
          senderName: offer.senderName,
          senderDeviceId: offer.senderDeviceId,
          senderAvatar: offer.senderAvatar,
          files: files,
          senderHttpHost: offer.senderHost,
          senderHttpPort: offer.senderPort,
          caption: offer.caption,
        );

    final waitMs = offer.expiresAtMs - DateTime.now().millisecondsSinceEpoch;
    if (waitMs > 0) {
      Future.delayed(Duration(milliseconds: waitMs), () {
        final m = ref
            .read(messageListProvider.notifier)
            .findIncomingByShareId(offer.shareId);
        if (m != null && m.status == TransferMessageStatus.pending) {
          ref
              .read(messageListProvider.notifier)
              .expireIncomingByShareId(offer.shareId, reason: '等待超时');
        }
      });
    }

    final summary = files.isEmpty
        ? '文字消息'
        : files.length == 1
            ? (files.first['name'] as String? ?? '文件')
            : '${files.length} 个文件';
    NotificationService.instance.showIncomingTransfer(
      senderName: offer.senderName,
      fileName: summary,
    );
  }

  Future<void> _onIncomingShareCancel(LanShareCancelPayload cancel) async {
    ref
        .read(messageListProvider.notifier)
        .rejectByShareId(cancel.shareId, reason: '发送方已取消');
  }

  /// 接收方点击接受/拒绝后，回调发送方 HTTP
  Future<void> receiverRespondToShare(
    TransferMessage msg,
    bool accepted,
  ) async {
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
      } else {
        ref
            .read(messageListProvider.notifier)
            .markOutgoingShareFailedByShareId(shareId, '传输中断或接收失败，可让对方重试接收');
        final session = _outgoingShares.remove(shareId);
        if (session != null) {
          session.cancelled = true;
          session.expiryTimer.cancel();
        }
      }
    } else {
      _outboundUploadRefCount[shareId] = next;
    }
  }

  void _finalizeOutboundShareDelivery(String shareId) {
    final session = _outgoingShares.remove(shareId);
    if (session != null) {
      if (!session.cancelled) {
        session.cancelled = true;
        session.expiryTimer.cancel();
      }
      unawaited(
        deleteManagedTransferTempPaths(
          session.managedTempPathsToDeleteAfterDelivery,
        ),
      );
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

      final fileSizes = <int>[];
      for (final path in session.filePaths) {
        final f = File(path);
        fileSizes.add(await f.exists() ? await f.length() : 0);
      }
      final totalBytes = fileSizes.fold<int>(0, (a, b) => a + b);
      final n = session.filePaths.length;

      var expected = 0;
      var uploaded = 0;
      var cumulativeBase = 0;
      var lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);
      var lastProgressValue = -1.0;

      void pushOutgoingProgress(double p) {
        final clamped = p.clamp(0.0, 1.0);
        final now = DateTime.now();
        if (now.difference(lastProgressAt).inMilliseconds < 180 &&
            (clamped - lastProgressValue).abs() < 0.015 &&
            clamped < 0.999) {
          return;
        }
        lastProgressAt = now;
        lastProgressValue = clamped;
        ref
            .read(messageListProvider.notifier)
            .updateOutgoingProgressByShareId(session.shareId, clamped);
      }

      if (n == 0) {
        pushOutgoingProgress(1.0);
        batchOk = true;
      } else {
        for (var i = 0; i < n; i++) {
          final path = session.filePaths[i];
          final f = File(path);
          if (!await f.exists()) continue;
          expected++;
          if (session.cancelled) break;

          final fileSize = fileSizes[i];
          var fileSent = false;

          for (var outer = 0; outer < _lanUploadOuterRetries; outer++) {
            if (session.cancelled) break;
            try {
              await transfer.sendLocalFileWithResume(
                ip: device.ip,
                port: device.port,
                filePath: path,
                senderName: senderName,
                senderAvatar: senderAvatar,
                senderDeviceId: senderDeviceId,
                shareId: session.shareId,
                fileIndex: i,
                fileCount: n,
                batchTotalBytes: totalBytes,
                batchBaseBytes: cumulativeBase,
                onProgress: pushOutgoingProgress,
                cancelToken: session.uploadCancelToken,
              );
              fileSent = true;
              uploaded++;
              break;
            } catch (e) {
              final es = e.toString();
              debugPrint(
                'Upload attempt ${outer + 1}/$_lanUploadOuterRetries: $e',
              );
              if (es.contains('已取消') || es.contains('拒绝')) {
                break;
              }
              if (outer >= _lanUploadOuterRetries - 1) {
                break;
              }
              await Future<void>.delayed(
                Duration(milliseconds: 350 * (outer + 1)),
              );
            }
          }

          if (!fileSent) break;
          cumulativeBase += fileSize;
        }
        batchOk = expected > 0 && uploaded == expected;
      }
    } finally {
      _onOutboundUploadFinished(session.shareId, batchOk);
    }
  }

  /// 发起批量分享：先发邀约，对端接受后再按文件顺序流式上传（多设备可并行）
  /// 返回 shareId，供展示「分享链接」与取消
  Future<String> startBatchShare({
    required List<String> absoluteFilePaths,
    required List<String> targetDeviceIds,
    String? caption,
  }) async {
    final trimmedCaption = caption?.trim();
    if (absoluteFilePaths.isEmpty &&
        (trimmedCaption == null || trimmedCaption.isEmpty)) {
      throw Exception('请输入文字或选择至少一个文件');
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
    final expiresAt = DateTime.now()
        .add(const Duration(minutes: 2))
        .millisecondsSinceEpoch;

    final files = <LanShareFileMeta>[];
    for (final path in absoluteFilePaths) {
      final f = File(path);
      if (!await f.exists()) continue;
      files.add(
        LanShareFileMeta(name: p.basename(path), size: await f.length()),
      );
    }
    if (absoluteFilePaths.isNotEmpty && files.isEmpty) {
      throw Exception('无法读取所选文件');
    }

    final targets = state
        .where((d) => targetDeviceIds.contains(d.deviceId) && d.isOnline)
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
      caption: trimmedCaption != null && trimmedCaption.isNotEmpty
          ? trimmedCaption
          : null,
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

    final managedTemp = <String>[];
    for (final path in absoluteFilePaths) {
      if (await isManagedTransferTempPath(path) &&
          !managedTemp.contains(path)) {
        managedTemp.add(path);
      }
    }

    _outgoingShares[shareId] = _OutgoingShare(
      shareId: shareId,
      filePaths: List<String>.from(absoluteFilePaths),
      targets: targets,
      expiryTimer: timer,
      managedTempPathsToDeleteAfterDelivery: managedTemp,
    );

    final fileMaps = files.map((e) => e.toJson()).toList();
    ref
        .read(messageListProvider.notifier)
        .addOutgoingBatchShare(
          shareId: shareId,
          absoluteFilePaths: List<String>.from(absoluteFilePaths),
          targetDeviceIds: targets.map((d) => d.deviceId).toList(),
          senderName: senderName,
          senderDeviceId: senderDeviceId,
          senderAvatar: senderAvatar,
          files: fileMaps,
          caption: trimmedCaption != null && trimmedCaption.isNotEmpty
              ? trimmedCaption
              : null,
        );
    return shareId;
  }

  void cancelOutgoingShare(String shareId, {bool userCancelled = false}) {
    final session = _outgoingShares.remove(shareId);
    if (session != null && !session.cancelled) {
      session.cancelled = true;
      session.expiryTimer.cancel();
      session.uploadCancelToken.cancel();

      final transfer = LanTransferService();
      final cancel = LanShareCancelPayload(shareId: shareId);
      for (final d in session.targets) {
        unawaited(
          transfer.postShareCancel(ip: d.ip, port: d.port, payload: cancel),
        );
      }
    }

    ref
        .read(messageListProvider.notifier)
        .expireOutgoingShareIfPending(
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

    final msg = ref
        .read(messageListProvider.notifier)
        .findIncomingByShareId(sid);
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
    final speed = ref.read(transferReceiveSpeedProvider.notifier);
    final basis = ctx.batchTotalBytes > 0 ? ctx.batchTotalBytes : ctx.fileSize;

    if (ctx.shareId != null && ctx.shareId!.isNotEmpty) {
      speed.tick(ctx.shareId!, batchProgress, basis);
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
        speed.tick(msg.id, batchProgress, basis);
        ref
            .read(messageListProvider.notifier)
            .updateProgress(msg.id, batchProgress);
      }
    }
  }

  void _onReceiveUploadComplete(LanUploadContext ctx) {
    final msgNotifier = ref.read(messageListProvider.notifier);
    final savedPath = ctx.savedAbsolutePath;

    if (ctx.shareId != null && ctx.shareId!.isNotEmpty) {
      if (savedPath != null) {
        msgNotifier.setIncomingShareSavedPath(
          shareId: ctx.shareId!,
          fileIndex: ctx.fileIndex,
          fileCount: ctx.fileCount,
          absolutePath: savedPath,
        );
      }
      if (ctx.fileIndex == ctx.fileCount - 1) {
        ref.read(transferReceiveSpeedProvider.notifier).clear(ctx.shareId!);
        final msg = msgNotifier.findIncomingByShareId(ctx.shareId!);
        if (msg != null) {
          msgNotifier.markCompleted(msg.id);
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
        if (savedPath != null) {
          msgNotifier.setIncomingSavedPathsById(msg.id, [savedPath]);
        }
        ref.read(transferReceiveSpeedProvider.notifier).clear(msg.id);
        msgNotifier.markCompleted(msg.id);
        NotificationService.instance.showTransferCompleted(
          senderName: msg.senderName,
          fileName: ctx.fileName,
        );
      }
    }
    ref.read(cloudFileListProvider.notifier).refresh();
  }

  void _onReceiveUploadError(LanUploadContext ctx, String error) {
    debugPrint(
      '[LAN /upload][recv-ui] file=${ctx.fileName} shareId=${ctx.shareId} err=$error',
    );
    if (ctx.shareId != null && ctx.shareId!.isNotEmpty) {
      ref.read(transferReceiveSpeedProvider.notifier).clear(ctx.shareId!);
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
        ref.read(transferReceiveSpeedProvider.notifier).clear(msg.id);
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

  Future<void> sendFile(
    LanDevice target,
    String filePath, {
    LanCancelToken? cancelToken,
    bool useResume = true,
  }) async {
    final senderName = ref.read(deviceNameProvider);
    final senderAvatar = ref.read(deviceAvatarProvider);
    final senderDeviceId = ref.read(deviceIdProvider) ?? '';
    final transfer = LanTransferService();

    final isAlive = await transfer.ping(target.ip, target.port);
    if (!isAlive) {
      throw Exception('设备无响应');
    }

    if (useResume) {
      await transfer.sendLocalFileWithResume(
        ip: target.ip,
        port: target.port,
        filePath: filePath,
        senderName: senderName,
        senderAvatar: senderAvatar,
        senderDeviceId: senderDeviceId,
        cancelToken: cancelToken,
      );
      return;
    }

    await transfer.sendFile(
      ip: target.ip,
      port: target.port,
      filePath: filePath,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderDeviceId: senderDeviceId,
      onProgress: (p) {},
      cancelToken: cancelToken,
    );
  }

  Future<void> sendFileStream(
    LanDevice target, {
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    LanCancelToken? cancelToken,
    int resumeFromOffset = 0,
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
      resumeFromOffset: resumeFromOffset,
      onProgress: (p) {},
      cancelToken: cancelToken,
    );
  }
}
