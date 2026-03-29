import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../services/local_storage_service.dart';
import '../models/transfer_message.dart';

part 'message_provider.g.dart';

const _messageListKey = 'message_list_v1';
const _maxPersistedMessages = 100;
/// 局域网批量分享（含收/发）最多保留条数
const _maxShareBatchMessages = 50;

@Riverpod(keepAlive: true)
class MessageList extends _$MessageList {
  List<TransferMessage> _trimToLimit(List<TransferMessage> messages) {
    final shareMsgs = messages
        .where((m) => m.isBatch && m.shareId != null)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final otherMsgs = messages
        .where((m) => !(m.isBatch && m.shareId != null))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final topShare = shareMsgs.take(_maxShareBatchMessages).toList();
    final remaining = _maxPersistedMessages - topShare.length;
    final topOther = otherMsgs.take(remaining).toList();

    final merged = [...topShare, ...topOther];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged.take(_maxPersistedMessages).toList();
  }

  @override
  List<TransferMessage> build() {
    final raw = LocalStorageService.instance.get<String>(_messageListKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final jsonList = jsonDecode(raw) as List<dynamic>;
      return _trimToLimit(
        jsonList
            .map((e) => TransferMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist() async {
    final trimmed = _trimToLimit(state);
    if (trimmed.length != state.length) {
      state = trimmed;
    }
    final payload = jsonEncode(trimmed.map((m) => m.toJson()).toList());
    await LocalStorageService.instance.set<String>(_messageListKey, payload);
  }

  TransferMessage addIncoming({
    required String fileName,
    required int fileSize,
    required String senderName,
    required String senderDeviceId,
    required int senderAvatar,
  }) {
    final msg = TransferMessage(
      id: const Uuid().v4(),
      fileName: fileName,
      fileSize: fileSize,
      senderName: senderName,
      senderDeviceId: senderDeviceId,
      senderAvatar: senderAvatar,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    state = _trimToLimit([msg, ...state]);
    _persist();
    return msg;
  }

  /// 局域网批量分享邀约（仅元数据）
  TransferMessage addIncomingBatchOffer({
    required String shareId,
    required String senderName,
    required String senderDeviceId,
    required int senderAvatar,
    required List<Map<String, dynamic>> files,
    required String senderHttpHost,
    required int senderHttpPort,
  }) {
    final totalSize = files.fold<int>(
      0,
      (s, e) => s + ((e['size'] as num?)?.toInt() ?? 0),
    );
    final batchJson = jsonEncode(files);
    final msg = TransferMessage(
      id: const Uuid().v4(),
      shareId: shareId,
      isBatch: true,
      batchFilesJson: batchJson,
      fileName: files.length == 1
          ? (files.first['name'] as String? ?? '文件')
          : '共 ${files.length} 个文件',
      fileSize: totalSize,
      senderName: senderName,
      senderDeviceId: senderDeviceId,
      senderAvatar: senderAvatar,
      senderHttpHost: senderHttpHost,
      senderHttpPort: senderHttpPort,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    state = _trimToLimit([msg, ...state]);
    _persist();
    return msg;
  }

  /// 本机发起的批量分享（写入历史，供过期后重试）
  TransferMessage addOutgoingBatchShare({
    required String shareId,
    required List<String> absoluteFilePaths,
    required List<String> targetDeviceIds,
    required String senderName,
    required String senderDeviceId,
    required int senderAvatar,
    required List<Map<String, dynamic>> files,
  }) {
    final totalSize = files.fold<int>(
      0,
      (s, e) => s + ((e['size'] as num?)?.toInt() ?? 0),
    );
    final batchJson = jsonEncode(files);
    final msg = TransferMessage(
      id: const Uuid().v4(),
      shareId: shareId,
      isBatch: true,
      isOutgoing: true,
      batchFilesJson: batchJson,
      localFilePathsJson: jsonEncode(absoluteFilePaths),
      targetDeviceIdsJson: jsonEncode(targetDeviceIds),
      fileName: files.length == 1
          ? (files.first['name'] as String? ?? '文件')
          : '共 ${files.length} 个文件',
      fileSize: totalSize,
      senderName: senderName,
      senderDeviceId: senderDeviceId,
      senderAvatar: senderAvatar,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    state = _trimToLimit([msg, ...state]);
    _persist();
    return msg;
  }

  /// 仅用于接收方：上传/匹配消息
  TransferMessage? findIncomingByShareId(String shareId) {
    for (final m in state) {
      if (m.shareId == shareId && !m.isOutgoing) return m;
    }
    return null;
  }

  TransferMessage? findByShareId(String shareId) {
    for (final m in state) {
      if (m.shareId == shareId) return m;
    }
    return null;
  }

  void updateProgressByShareId(String shareId, double progress) {
    state = [
      for (final m in state)
        if (m.shareId == shareId && !m.isOutgoing)
          m.copyWith(progress: progress)
        else
          m,
    ];
    _persist();
  }

  void rejectByShareId(String shareId, {String? reason}) {
    state = [
      for (final m in state)
        if (m.shareId == shareId && !m.isOutgoing)
          m.copyWith(
            status: TransferMessageStatus.rejected,
            errorMessage: reason,
          )
        else
          m,
    ];
    _persist();
  }

  /// 接收方：等待超时未操作
  void expireIncomingByShareId(String shareId, {String? reason}) {
    state = [
      for (final m in state)
        if (m.shareId == shareId &&
            !m.isOutgoing &&
            m.status == TransferMessageStatus.pending)
          m.copyWith(
            status: TransferMessageStatus.expired,
            errorMessage: reason ?? '等待超时',
          )
        else
          m,
    ];
    _persist();
  }

  /// 发送方：超时或取消时仍无人完成接收
  void expireOutgoingShareIfPending(String shareId, {String? reason}) {
    state = [
      for (final m in state)
        if (m.shareId == shareId &&
            m.isOutgoing &&
            m.status == TransferMessageStatus.pending)
          m.copyWith(
            status: TransferMessageStatus.expired,
            errorMessage: reason ?? '已超时',
          )
        else
          m,
    ];
    _persist();
  }

  /// 发送方：对端已接受，开始推流
  void markOutgoingShareReceivingByShareId(String shareId) {
    state = [
      for (final m in state)
        if (m.shareId == shareId &&
            m.isOutgoing &&
            m.status == TransferMessageStatus.pending)
          m.copyWith(status: TransferMessageStatus.receiving)
        else
          m,
    ];
    _persist();
  }

  /// 发送方：整批已成功送达（更新消息与分享页状态）
  void markOutgoingShareCompletedByShareId(String shareId) {
    state = [
      for (final m in state)
        if (m.shareId == shareId && m.isOutgoing)
          m.copyWith(
            status: TransferMessageStatus.completed,
            progress: 1.0,
          )
        else
          m,
    ];
    _persist();
  }

  /// 发送方：全部接收端均未成功完成传输（或本机上传已放弃）
  void markOutgoingShareFailedByShareId(String shareId, String error) {
    state = [
      for (final m in state)
        if (m.shareId == shareId &&
            m.isOutgoing &&
            m.status != TransferMessageStatus.completed)
          m.copyWith(
            status: TransferMessageStatus.failed,
            errorMessage: error,
          )
        else
          m,
    ];
    _persist();
  }

  void updateStatus(String id, TransferMessageStatus status) {
    state = [
      for (final m in state)
        if (m.id == id) m.copyWith(status: status) else m,
    ];
    _persist();
  }

  void updateProgress(String id, double progress) {
    state = [
      for (final m in state)
        if (m.id == id) m.copyWith(progress: progress) else m,
    ];
    _persist();
  }

  void markCompleted(String id) {
    updateStatus(id, TransferMessageStatus.completed);
  }

  void markFailed(String id, String error) {
    state = [
      for (final m in state)
        if (m.id == id)
          m.copyWith(
            status: TransferMessageStatus.failed,
            errorMessage: error,
          )
        else
          m,
    ];
    _persist();
  }

  void remove(String id) {
    state = state.where((m) => m.id != id).toList();
    _persist();
  }

  void clearAll() {
    state = [];
    _persist();
  }
}

@riverpod
int pendingMessageCount(Ref ref) {
  final messages = ref.watch(messageListProvider);
  return messages
      .where(
        (m) =>
            !m.isOutgoing &&
            m.status == TransferMessageStatus.pending,
      )
      .length;
}
