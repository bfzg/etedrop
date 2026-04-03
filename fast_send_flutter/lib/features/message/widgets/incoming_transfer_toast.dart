import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../device/models/device_config.dart';
import '../../lan/providers/lan_provider.dart';
import '../models/transfer_message.dart';
import '../providers/incoming_transfer_toast_provider.dart';
import '../providers/message_provider.dart';

/// 右下角应用内接收提示（头像、发送方、内容摘要、接收/拒绝）。
class IncomingTransferToast extends ConsumerWidget {
  const IncomingTransferToast({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toastId = ref.watch(incomingTransferToastMessageIdProvider);
    final messages = ref.watch(messageListProvider);

    if (toastId == null) return const SizedBox.shrink();

    TransferMessage? msg;
    for (final m in messages) {
      if (m.id == toastId) {
        msg = m;
        break;
      }
    }

    if (msg == null ||
        msg.isOutgoing ||
        msg.status != TransferMessageStatus.pending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(incomingTransferToastMessageIdProvider.notifier)
            .setMessageId(null);
      });
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final summary = msg.fileName;
    final caption = (msg.caption ?? '').trim();

    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset(
                      memojiAssetPath(msg.senderAvatar),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person,
                        size: 28,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.senderName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (caption.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            caption,
                            style: theme.textTheme.bodySmall,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final msgNotifier = ref.read(
                        messageListProvider.notifier,
                      );
                      final lanNotifier = ref.read(
                        lanManagerProvider.notifier,
                      );
                      if (msg!.isBatch && msg.shareId != null) {
                        try {
                          await lanNotifier.receiverRespondToShare(
                            msg,
                            false,
                          );
                        } catch (_) {}
                      }
                      msgNotifier.updateStatus(
                        msg.id,
                        TransferMessageStatus.rejected,
                      );
                      ref
                          .read(incomingTransferToastMessageIdProvider.notifier)
                          .setMessageId(null);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: Text(l10n.reject),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final msgNotifier = ref.read(
                        messageListProvider.notifier,
                      );
                      final lanNotifier = ref.read(
                        lanManagerProvider.notifier,
                      );
                      final m = msg!;
                      if (m.isBatch && m.shareId != null) {
                        msgNotifier.updateStatus(
                          m.id,
                          TransferMessageStatus.accepted,
                        );
                        try {
                          await lanNotifier.receiverRespondToShare(m, true);
                          var textOnlyOffer = false;
                          final raw = m.batchFilesJson;
                          if (raw != null && raw.isNotEmpty) {
                            try {
                              final list = jsonDecode(raw) as List<dynamic>;
                              textOnlyOffer = list.isEmpty;
                            } catch (_) {}
                          }
                          if (textOnlyOffer) {
                            msgNotifier.markCompleted(m.id);
                          }
                        } catch (e) {
                          msgNotifier.updateStatus(
                            m.id,
                            TransferMessageStatus.pending,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.notifySenderFailed('$e'),
                                ),
                              ),
                            );
                          }
                          return;
                        }
                      } else {
                        msgNotifier.updateStatus(
                          m.id,
                          TransferMessageStatus.accepted,
                        );
                      }
                      ref
                          .read(incomingTransferToastMessageIdProvider.notifier)
                          .setMessageId(null);
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.receiveAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
