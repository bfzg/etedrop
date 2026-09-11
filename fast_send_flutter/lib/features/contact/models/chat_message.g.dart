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
  kind:
      $enumDecodeNullable(_$ChatMessageKindEnumMap, json['kind']) ??
      ChatMessageKind.text,
  fileName: json['fileName'] as String?,
  fileSize: (json['fileSize'] as num?)?.toInt(),
  localPath: json['localPath'] as String?,
  shareId: json['shareId'] as String?,
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
      'kind': _$ChatMessageKindEnumMap[instance.kind]!,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'localPath': instance.localPath,
      'shareId': instance.shareId,
    };

const _$ChatMessageStatusEnumMap = {
  ChatMessageStatus.sending: 'sending',
  ChatMessageStatus.sent: 'sent',
  ChatMessageStatus.delivered: 'delivered',
  ChatMessageStatus.failed: 'failed',
};

const _$ChatMessageKindEnumMap = {
  ChatMessageKind.text: 'text',
  ChatMessageKind.file: 'file',
};
