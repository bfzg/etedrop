import 'dart:convert';
import 'dart:io';

import '../models/chat_message.dart';

class LanChatPayload {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final int senderAvatar;
  final String text;
  final int timestamp;
  final String? conversationTitle;
  final List<String> memberIds;

  const LanChatPayload({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    required this.timestamp,
    this.conversationTitle,
    this.memberIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'conversationId': conversationId,
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'text': text,
    'timestamp': timestamp,
    if (conversationTitle != null && conversationTitle!.isNotEmpty)
      'conversationTitle': conversationTitle,
    if (memberIds.isNotEmpty) 'memberIds': memberIds,
  };

  factory LanChatPayload.fromJson(Map<String, dynamic> json) {
    return LanChatPayload(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: (json['senderAvatar'] as num?)?.toInt() ?? 1,
      text: json['text'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      conversationTitle: json['conversationTitle'] as String?,
      memberIds: (json['memberIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  ChatMessage toChatMessage({String? normalizedConversationId}) => ChatMessage(
    messageId: messageId,
    conversationId: normalizedConversationId ?? conversationId,
    senderId: senderId,
    senderName: senderName,
    senderAvatar: senderAvatar,
    text: text,
    timestamp: timestamp,
  );
}

class LanChatService {
  Future<bool> send({
    required String ip,
    required int port,
    required LanChatPayload payload,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(
        Uri(scheme: 'http', host: ip, port: port, path: '/chat-message'),
      );
      request.headers.contentType = ContentType.json;
      final bytes = utf8.encode(jsonEncode(payload.toJson()));
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      await response.drain<void>();
      return response.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
