import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/transfer_message.dart';

class MessageCardStatusBadge extends StatelessWidget {
  final TransferMessage message;
  final AppLocalizations l10n;

  const MessageCardStatusBadge({
    super.key,
    required this.message,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final status = message.status;
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
        _expiredBadgeLabel(message),
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

  /// 过期原因（已超时 / 已取消 / 等待超时等）只在角标展示，与 [l10n.statusExpired] 二选一。
  String _expiredBadgeLabel(TransferMessage m) {
    final detail = m.errorMessage?.trim();
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }
    return l10n.statusExpired;
  }
}
