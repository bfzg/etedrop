import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/utils/format_utils.dart';
import '../../../styles/styles.dart';
import '../../device/models/device_config.dart';
import '../../lan/models/lan_device.dart';
import '../../lan/providers/lan_provider.dart';
import '../../lan/providers/transfer_receive_speed_provider.dart';
import '../models/transfer_message.dart';
import '../providers/message_provider.dart';

class MessageCard extends ConsumerWidget {
  final TransferMessage message;

  const MessageCard({super.key, required this.message});

  List<Map<String, dynamic>>? _batchFiles(TransferMessage m) {
    if (!m.isBatch || m.batchFilesJson == null) return null;
    try {
      final list = jsonDecode(m.batchFilesJson!) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  String _outgoingTargetSummary(WidgetRef ref, TransferMessage m) {
    if (!m.isOutgoing || m.targetDeviceIdsJson == null) return '';
    try {
      final ids =
          (jsonDecode(m.targetDeviceIdsJson!) as List).map((e) => e as String).toList();
      final devices = ref.watch(lanManagerProvider);
      final names = <String>[];
      for (final id in ids) {
        LanDevice? found;
        for (final d in devices) {
          if (d.deviceId == id) {
            found = d;
            break;
          }
        }
        if (found != null) names.add(found.deviceName);
      }
      if (names.isEmpty) return '${ids.length} 台设备';
      if (names.length <= 2) return names.join('、');
      return '${names.take(2).join('、')} 等 ${ids.length} 台';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final receiveSpeeds = ref.watch(transferReceiveSpeedProvider);
    final receiveSpeedKey = message.shareId ?? message.id;
    final receiveBps =
        !message.isOutgoing ? receiveSpeeds[receiveSpeedKey] : null;
    final isPending = message.status == TransferMessageStatus.pending;
    final showIncomingActions = isPending && !message.isOutgoing;
    final batch = _batchFiles(message);

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
                  child: ClipOval(
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              message.isOutgoing ? '我' : message.senderName,
                              style: AppTextStyles.secondary(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (message.isOutgoing) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '发送',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (message.isOutgoing && message.isBatch) ...[
                        const SizedBox(height: 4),
                        Text(
                          '发给 ${_outgoingTargetSummary(ref, message)}',
                          style: AppTextStyles.hint(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        FormatUtils.dateTime(message.timestamp),
                        style: AppTextStyles.secondary(context),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: message.status),
              ],
            ),
            const SizedBox(height: 12),
            if (batch != null && batch.isNotEmpty) ...[
              Text(
                message.fileName,
                style: AppTextStyles.fileName(context),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: batch.map((f) {
                  final name = f['name'] as String? ?? '';
                  final size = (f['size'] as num?)?.toInt() ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          FormatUtils.fileSize(size),
                          style: AppTextStyles.hint(context),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Text(
                '合计 ${FormatUtils.fileSize(message.fileSize)}',
                style: AppTextStyles.hint(context),
              ),
            ] else ...[
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
            ],
            if (message.status == TransferMessageStatus.receiving) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: message.progress <= 0 ? null : message.progress,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.isOutgoing
                        ? '发送中 ${(message.progress * 100).toStringAsFixed(0)}%'
                        : '接收中 ${(message.progress * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.secondary(context),
                  ),
                  if (receiveBps != null && receiveBps > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '约 ${FormatUtils.transferSpeed(receiveBps)}',
                      style: AppTextStyles.hint(context),
                    ),
                  ],
                ],
              ),
            ],
            if (message.status == TransferMessageStatus.failed &&
                message.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(message.errorMessage!, style: AppTextStyles.error(context)),
            ],
            if (message.status == TransferMessageStatus.expired &&
                message.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                message.errorMessage!,
                style: AppTextStyles.secondary(context),
              ),
            ],
            if (message.isOutgoing &&
                message.status == TransferMessageStatus.pending) ...[
              const SizedBox(height: 8),
              Text(
                '等待对方在消息内接受（2 分钟内有效）',
                style: AppTextStyles.hint(context),
              ),
            ],
            if (message.isOutgoing &&
                message.status == TransferMessageStatus.expired &&
                message.localFilePathsJson != null &&
                message.targetDeviceIdsJson != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () =>
                      _retryOutgoingShare(context, ref, message),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重试发送'),
                ),
              ),
            ],
            if (showIncomingActions) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      if (message.isBatch && message.shareId != null) {
                        try {
                          await ref
                              .read(lanManagerProvider.notifier)
                              .receiverRespondToShare(message, false);
                        } catch (_) {}
                      }
                      ref.read(messageListProvider.notifier).updateStatus(
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
                    onPressed: () async {
                      if (message.isBatch && message.shareId != null) {
                        ref.read(messageListProvider.notifier).updateStatus(
                              message.id,
                              TransferMessageStatus.accepted,
                            );
                        try {
                          await ref
                              .read(lanManagerProvider.notifier)
                              .receiverRespondToShare(message, true);
                        } catch (e) {
                          ref.read(messageListProvider.notifier).updateStatus(
                                message.id,
                                TransferMessageStatus.pending,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('无法通知发送方: $e')),
                            );
                          }
                        }
                      } else {
                        ref.read(messageListProvider.notifier).updateStatus(
                              message.id,
                              TransferMessageStatus.accepted,
                            );
                      }
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

Future<void> _retryOutgoingShare(
  BuildContext context,
  WidgetRef ref,
  TransferMessage message,
) async {
  final pathsRaw = message.localFilePathsJson;
  final idsRaw = message.targetDeviceIdsJson;
  if (pathsRaw == null || idsRaw == null) return;
  try {
    final paths =
        (jsonDecode(pathsRaw) as List).map((e) => e as String).toList();
    final ids =
        (jsonDecode(idsRaw) as List).map((e) => e as String).toList();
    final existing = <String>[];
    for (final p in paths) {
      if (await File(p).exists()) {
        existing.add(p);
      }
    }
    if (existing.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('本地文件已不存在或已移动，无法重试')),
        );
      }
      return;
    }
    if (ids.isEmpty) return;
    await ref.read(lanManagerProvider.notifier).startBatchShare(
          absoluteFilePaths: existing,
          targetDeviceIds: ids,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重新发起分享')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('重试失败: $e')),
      );
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
      TransferMessageStatus.expired => (
        '已过期',
        Theme.of(context).colorScheme.onSurfaceVariant,
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
