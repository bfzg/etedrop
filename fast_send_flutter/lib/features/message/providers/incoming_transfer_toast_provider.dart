import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 应用内右下角「接收文件」提示当前对应的消息 id（`TransferMessage.id`）。
/// 为 null 时不显示。
final incomingTransferToastMessageIdProvider =
    NotifierProvider<IncomingTransferToastMessageIdNotifier, String?>(
  IncomingTransferToastMessageIdNotifier.new,
);

class IncomingTransferToastMessageIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setMessageId(String? id) => state = id;
}
