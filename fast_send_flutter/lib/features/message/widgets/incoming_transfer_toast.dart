import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/ui/e_button.dart';
import '../../device/models/device_config.dart';
import '../../lan/providers/lan_provider.dart';
import '../../settings/providers/transfer_receive_prefs_provider.dart';
import '../models/transfer_message.dart';
import '../providers/incoming_transfer_toast_provider.dart';
import '../providers/message_provider.dart';

/// 右下角应用内接收提示（头像、发送方、内容摘要；手动模式为接收/拒绝，自动模式仅提示）。
class IncomingTransferToast extends ConsumerWidget {
  const IncomingTransferToast({super.key});

  static bool _shouldShowToast(TransferMessage msg, bool autoReceiveLan) {
    if (msg.isOutgoing) return false;
    if (!autoReceiveLan) {
      return msg.status == TransferMessageStatus.pending;
    }
    return msg.status == TransferMessageStatus.pending ||
        msg.status == TransferMessageStatus.accepted ||
        msg.status == TransferMessageStatus.receiving;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toastId = ref.watch(incomingTransferToastMessageIdProvider);
    final messages = ref.watch(messageListProvider);
    final autoReceiveLan = ref.watch(autoReceiveLanTransferProvider);

    if (toastId == null) return const SizedBox.shrink();

    TransferMessage? msg;
    for (final m in messages) {
      if (m.id == toastId) {
        msg = m;
        break;
      }
    }

    if (msg == null || !_shouldShowToast(msg, autoReceiveLan)) {
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
              if (autoReceiveLan) ...[
                if (msg.status == TransferMessageStatus.receiving) ...[
                  LinearProgressIndicator(
                    value: msg.progress <= 0 ? null : msg.progress,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.receivingPercent(
                      (msg.progress * 100).toStringAsFixed(0),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.download_done_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.transferAutoReceivingHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    EButton(
                      variant: EButtonVariant.outlined,
                      destructive: true,
                      text: l10n.reject,
                      size: EButtonSize.sm,
                      radius: 99,
                      onPressed: () async {
                        final msgNotifier = ref.read(
                          messageListProvider.notifier,
                        );
                        final lanNotifier =
                            ref.read(lanManagerProvider.notifier);
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
                            .read(
                              incomingTransferToastMessageIdProvider.notifier,
                            )
                            .setMessageId(null);
                      },
                    ),
                    const SizedBox(width: 8),
                    EButton(
                      variant: EButtonVariant.primary,
                      icon: Icons.download,
                      radius: 99,
                      size: EButtonSize.sm,
                      text: l10n.receiveAction,
                      onPressed: () async {
                        final msgNotifier = ref.read(
                          messageListProvider.notifier,
                        );
                        final lanNotifier =
                            ref.read(lanManagerProvider.notifier);
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
                            .read(
                              incomingTransferToastMessageIdProvider.notifier,
                            )
                            .setMessageId(null);
                      },
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
