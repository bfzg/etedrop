import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/utils/format_utils.dart';
import '../../../styles/styles.dart';
import '../models/transfer_message.dart';
import '../providers/message_provider.dart';

class MessagePage extends ConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageListProvider);
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      appBar: isDesktopLayout
          ? null
          : AppBar(
              title: const Text('消息'),
              actions: [
                if (messages.isNotEmpty)
                  IconButton(
                    onPressed: () =>
                        ref.read(messageListProvider.notifier).clearAll(),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: '清空',
                  ),
              ],
            ),
      body: messages.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  Gap.md,
                  Text('暂无消息', style: AppTextStyles.hint(context)),
                  Gap.xs,
                  Text(
                    '当有设备向你发送文件时，会在这里显示',
                    style: AppTextStyles.secondary(context),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              itemCount: messages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _MessageCard(message: msg);
              },
            ),
    );
  }
}

class _MessageCard extends ConsumerWidget {
  final TransferMessage message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPending = message.status == TransferMessageStatus.pending;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _statusColor(theme).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _statusIcon(),
                    size: 20,
                    color: _statusColor(theme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.fileName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '来自 ${message.senderName} · ${FormatUtils.fileSize(message.fileSize)}',
                        style: AppTextStyles.secondary(context),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: message.status),
              ],
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

  Color _statusColor(ThemeData theme) {
    switch (message.status) {
      case TransferMessageStatus.pending:
        return theme.colorScheme.primary;
      case TransferMessageStatus.accepted:
      case TransferMessageStatus.receiving:
        return theme.colorScheme.primary;
      case TransferMessageStatus.completed:
        return Colors.green;
      case TransferMessageStatus.rejected:
        return theme.colorScheme.onSurfaceVariant;
      case TransferMessageStatus.failed:
        return theme.colorScheme.error;
    }
  }

  IconData _statusIcon() {
    switch (message.status) {
      case TransferMessageStatus.pending:
        return Icons.file_present_outlined;
      case TransferMessageStatus.accepted:
      case TransferMessageStatus.receiving:
        return Icons.downloading;
      case TransferMessageStatus.completed:
        return Icons.check_circle_outline;
      case TransferMessageStatus.rejected:
        return Icons.block_outlined;
      case TransferMessageStatus.failed:
        return Icons.error_outline;
    }
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
