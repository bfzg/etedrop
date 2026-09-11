import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum ChatMessageStatus { sending, sent, delivered, failed }

enum ChatMessageKind { text, file }

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String messageId,
    required String conversationId,
    required String senderId,
    required String senderName,
    required int senderAvatar,
    required String text,
    required int timestamp,
    @Default(false) bool isOutgoing,
    @Default(false) bool isRead,
    @Default(ChatMessageStatus.sent) ChatMessageStatus status,
    @Default(ChatMessageKind.text) ChatMessageKind kind,
    String? fileName,
    int? fileSize,
    String? localPath,
    String? shareId,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
