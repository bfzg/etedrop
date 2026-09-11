import 'package:flutter/material.dart';

import '../../../core/config/styles.dart';
import 'message_avatar.dart';

class ConversationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lastMessage;
  final int avatar;
  final bool selected;
  final bool online;
  final int unreadCount;
  final VoidCallback onTap;
  const ConversationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.avatar,
    required this.selected,
    required this.onTap,
    this.unreadCount = 0,
    this.lastMessage,
    this.online = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppStyles.primary;
    final secondaryTextColor = selected
        ? Colors.white.withValues(alpha: .78)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return Container(
      color: selected ? primary : Colors.transparent,
      child: ListTile(
        selected: selected,
        selectedColor: Colors.white,
        leading: Stack(
          children: [
            MessageAvatar(avatar: avatar, size: 44),
            if (online)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? primary
                          : Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),

            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lastMessage ?? subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
