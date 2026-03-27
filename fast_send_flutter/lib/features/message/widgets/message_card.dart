import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/utils/format_utils.dart';
import '../../../styles/styles.dart';
import '../../device/models/device_config.dart';
import '../models/transfer_message.dart';
import '../providers/message_provider.dart';

class MessageCard extends ConsumerWidget {
  final TransferMessage message;

  const MessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPending = message.status == TransferMessageStatus.pending;

    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          memojiAssetPath(message.senderAvatar),
                          fit: BoxFit.cover,
                          width: 46,
                          height: 46,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.person,
                            size: 24,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   message.fileName,
                      //   style: theme.textTheme.titleSmall,
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                      // const SizedBox(height: 2),  · ${FormatUtils.dateTime(message.timestamp)}
                      Text(
                        message.senderName,
                        style: AppTextStyles.secondary(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        FormatUtils.fileSize(message.fileSize),
                        style: AppTextStyles.secondary(context),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: message.status),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              message.fileName,
              style: AppTextStyles.fileName(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${FormatUtils.fileSize(message.fileSize)} · ${FormatUtils.dateTime(message.timestamp)}',
              style: AppTextStyles.hint(context),
            ),
            if (message.status == TransferMessageStatus.receiving) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: message.progress,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                '接收中 ${(message.progress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.secondary(context),
              ),
            ],
            if (message.status == TransferMessageStatus.failed &&
                message.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(message.errorMessage!, style: AppTextStyles.error(context)),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      ref
                          .read(messageListProvider.notifier)
                          .updateStatus(
                            message.id,
                            TransferMessageStatus.rejected,
                          );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: const Text('拒绝'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(messageListProvider.notifier)
                          .updateStatus(
                            message.id,
                            TransferMessageStatus.accepted,
                          );
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('接收'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TransferMessageStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TransferMessageStatus.pending => (
        '待处理',
        Theme.of(context).colorScheme.primary,
      ),
      TransferMessageStatus.accepted => ('已接受', Colors.green),
      TransferMessageStatus.receiving => (
        '接收中',
        Theme.of(context).colorScheme.primary,
      ),
      TransferMessageStatus.completed => ('已完成', Colors.green),
      TransferMessageStatus.rejected => (
        '已拒绝',
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      TransferMessageStatus.failed => (
        '失败',
        Theme.of(context).colorScheme.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
