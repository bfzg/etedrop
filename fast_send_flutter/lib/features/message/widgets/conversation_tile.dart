import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: .45),
          ),
        ),
      ),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppStyles.primary.withValues(alpha: 0.08),
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
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (unreadCount > 0)
              TDBadge(
                TDBadgeType.message,
                count: '$unreadCount',
                maxCount: '99',
                showZero: false,
              ),
          ],
        ),
        subtitle: Text(
          lastMessage ?? subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}
