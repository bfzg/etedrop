import 'package:flutter/material.dart';

import '../../../core/config/styles.dart';
import '../../contact/models/chat_message.dart';
import 'message_avatar.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.isOutgoing;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) ...[
              MessageAvatar(avatar: message.senderAvatar, size: 42),
              const SizedBox(width: 4),
            ],
            Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: mine
                    ? AppStyles.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
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
