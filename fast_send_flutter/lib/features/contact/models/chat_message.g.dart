// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  messageId: json['messageId'] as String,
  conversationId: json['conversationId'] as String,
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  senderAvatar: (json['senderAvatar'] as num).toInt(),
  text: json['text'] as String,
  timestamp: (json['timestamp'] as num).toInt(),
  isOutgoing: json['isOutgoing'] as bool? ?? false,
  isRead: json['isRead'] as bool? ?? false,
  status:
      $enumDecodeNullable(_$ChatMessageStatusEnumMap, json['status']) ??
      ChatMessageStatus.sent,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'senderAvatar': instance.senderAvatar,
      'text': instance.text,
      'timestamp': instance.timestamp,
      'isOutgoing': instance.isOutgoing,
      'isRead': instance.isRead,
      'status': _$ChatMessageStatusEnumMap[instance.status]!,
    };

const _$ChatMessageStatusEnumMap = {
  ChatMessageStatus.sending: 'sending',
  ChatMessageStatus.sent: 'sent',
  ChatMessageStatus.delivered: 'delivered',
  ChatMessageStatus.failed: 'failed',
};
