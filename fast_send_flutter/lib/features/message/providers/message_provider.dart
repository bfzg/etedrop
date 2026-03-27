import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../services/local_storage_service.dart';
import '../models/transfer_message.dart';

part 'message_provider.g.dart';

const _messageListKey = 'message_list_v1';
const _maxPersistedMessages = 100;

@Riverpod(keepAlive: true)
class MessageList extends _$MessageList {
  List<TransferMessage> _trimToLimit(List<TransferMessage> messages) {
    if (messages.length <= _maxPersistedMessages) return messages;
    return messages.take(_maxPersistedMessages).toList();
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
  return messages.where((m) => m.status == TransferMessageStatus.pending).length;
}
