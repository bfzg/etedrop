import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_message.freezed.dart';
part 'transfer_message.g.dart';

enum TransferMessageStatus {
  pending,
  accepted,
  rejected,
  receiving,
  completed,
  failed,
}

@freezed
abstract class TransferMessage with _$TransferMessage {
  const factory TransferMessage({
    required String id,
    required String fileName,
    required int fileSize,
    required String senderName,
    required String senderDeviceId,
    required int timestamp,
    @Default(TransferMessageStatus.pending) TransferMessageStatus status,
    @Default(0.0) double progress,
    String? errorMessage,
  }) = _TransferMessage;

  factory TransferMessage.fromJson(Map<String, dynamic> json) =>
      _$TransferMessageFromJson(json);
}
