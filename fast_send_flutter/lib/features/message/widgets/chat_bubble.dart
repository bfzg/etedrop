import 'package:flutter/material.dart';

import '../../../core/config/styles.dart';
import '../../contact/models/chat_message.dart';
import 'chat_attachment.dart';
import 'message_avatar.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;

  const ChatBubble({super.key, required this.message, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final mine = message.isOutgoing;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine) ...[
              MessageAvatar(avatar: message.senderAvatar, size: 42),
              const SizedBox(width: 4),
            ],
            Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: message.kind == ChatMessageKind.file
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.kind == ChatMessageKind.file
                    ? Colors.transparent
                    : mine
                    ? AppStyles.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: message.kind == ChatMessageKind.file
                  ? ChatAttachment(message: message, onDelete: onDelete)
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: mine ? Colors.white : null,
                        height: 1.35,
                      ),
                    ),
            ),
            if (mine) ...[
              const SizedBox(width: 4),
              MessageAvatar(avatar: message.senderAvatar, size: 42),
            ],
          ],
        ),
      ),
    );
  }
}
