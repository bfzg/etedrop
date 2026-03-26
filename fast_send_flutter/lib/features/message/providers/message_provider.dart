import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/transfer_message.dart';

part 'message_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageList extends _$MessageList {
  @override
  List<TransferMessage> build() => [];

  TransferMessage addIncoming({
    required String fileName,
    required int fileSize,
    required String senderName,
    required String senderDeviceId,
  }) {
    final msg = TransferMessage(
      id: const Uuid().v4(),
      fileName: fileName,
      fileSize: fileSize,
      senderName: senderName,
      senderDeviceId: senderDeviceId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    state = [msg, ...state];
    return msg;
  }

  void updateStatus(String id, TransferMessageStatus status) {
    state = [
      for (final m in state)
        if (m.id == id) m.copyWith(status: status) else m,
    ];
  }

  void updateProgress(String id, double progress) {
    state = [
      for (final m in state)
        if (m.id == id) m.copyWith(progress: progress) else m,
    ];
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
  }

  void remove(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

@riverpod
int pendingMessageCount(Ref ref) {
  final messages = ref.watch(messageListProvider);
  return messages.where((m) => m.status == TransferMessageStatus.pending).length;
}
