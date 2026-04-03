import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/transfer_message.dart';

class MessageCardStatusBadge extends StatelessWidget {
  final TransferMessageStatus status;
  final AppLocalizations l10n;

  const MessageCardStatusBadge({
    super.key,
    required this.status,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TransferMessageStatus.pending => (
        l10n.statusPending,
        Theme.of(context).colorScheme.primary,
      ),
      TransferMessageStatus.accepted => (l10n.statusAccepted, Colors.green),
      TransferMessageStatus.receiving => (
        l10n.statusReceiving,
        Theme.of(context).colorScheme.primary,
      ),
      TransferMessageStatus.completed => (l10n.statusCompleted, Colors.green),
      TransferMessageStatus.rejected => (
        l10n.statusRejected,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      TransferMessageStatus.failed => (
        l10n.statusFailed,
        Theme.of(context).colorScheme.error,
      ),
      TransferMessageStatus.expired => (
        l10n.statusExpired,
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
