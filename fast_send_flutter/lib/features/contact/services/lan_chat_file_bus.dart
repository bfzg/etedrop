import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

enum LanChatFileEventType { incomingOffer, saved, outgoingDelivered, failed }

class LanChatFileEvent {
  final LanChatFileEventType type;
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final int senderAvatar;
  final String fileName;
  final int fileSize;
  final int timestamp;
  final String? localPath;
  final String? shareId;
  final String? error;
  final String? conversationTitle;
  final List<String> memberIds;

  const LanChatFileEvent({
    required this.type,
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.fileName,
    required this.fileSize,
    required this.timestamp,
    this.localPath,
    this.shareId,
    this.error,
    this.conversationTitle,
    this.memberIds = const [],
  });
}

final _incomingLanChatFileController =
    StreamController<LanChatFileEvent>.broadcast();

void publishLanChatFileEvent(LanChatFileEvent event) {
  _incomingLanChatFileController.add(event);
}

final lanChatFileEventProvider = StreamProvider<LanChatFileEvent>((ref) {
  return _incomingLanChatFileController.stream;
});
