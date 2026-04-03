import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../styles/styles.dart';
import '../../device/models/device_config.dart';
import '../models/transfer_message.dart';
import 'message_card_recipient.dart';
import 'message_card_status_badge.dart';

class MessageCardHeader extends ConsumerWidget {
  final TransferMessage message;

  const MessageCardHeader({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final recipientInner = outgoingRecipientNamesOnly(ref, message, l10n);

    return Row(
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
              if (message.isOutgoing && recipientInner != null)
                Text(
                  l10n.messageOutgoingHeaderLine(recipientInner),
                  style: AppTextStyles.secondary(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              else if (message.isOutgoing)
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.meLabel,
                        style: AppTextStyles.secondary(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.sendingBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  message.senderName,
                  style: AppTextStyles.secondary(context),
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Text(
                FormatUtils.dateTime(message.timestamp),
                style: AppTextStyles.secondary(context),
              ),
            ],
          ),
        ),
        MessageCardStatusBadge(message: message, l10n: l10n),
      ],
    );
  }
}
