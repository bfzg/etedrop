import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../styles/styles.dart';
import '../../../widgets/ui/e_button.dart';
import '../../device/models/device_config.dart';
import '../../lan/models/lan_device.dart';
import '../../message/models/transfer_message.dart';
import '../../message/providers/message_provider.dart';

/// 发起局域网分享后的状态区：分享 ID / 链接文案、取消、倒计时；传输完成后与消息列表状态同步
class LanSharePanel extends ConsumerStatefulWidget {
  final String shareId;
  final DateTime expiresAt;

  /// 取消进行中的分享（通知对端 + 清空会话）
  final VoidCallback onCancelSharing;

  /// 仅关闭本卡片（已完成或无需再取消时）
  final VoidCallback onDismissRecord;

  /// 2 分钟到期且本地倒计时归零时回调（未完成传输时）
  final VoidCallback? onExpired;

  /// 本次邀约的目标设备（头像叠放）
  final List<LanDevice> recipients;

  const LanSharePanel({
    super.key,
    required this.shareId,
    required this.expiresAt,
    required this.onCancelSharing,
    required this.onDismissRecord,
    this.onExpired,
    this.recipients = const [],
  });

  @override
  ConsumerState<LanSharePanel> createState() => _LanSharePanelState();
}

class _LanSharePanelState extends ConsumerState<LanSharePanel> {
  Timer? _t;
  Duration _left = Duration.zero;
  bool _expiredNotified = false;

  TransferMessage? _outgoing() {
    for (final m in ref.watch(messageListProvider)) {
      if (m.shareId == widget.shareId && m.isOutgoing) {
        return m;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tick();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final outgoing = _outgoingFromRead();
    if (outgoing?.status == TransferMessageStatus.completed) {
      _t?.cancel();
      _t = null;
      if (mounted) {
        setState(() => _left = Duration.zero);
      }
      return;
    }

    final now = DateTime.now();
    final expired = !now.isBefore(widget.expiresAt);
    final left = widget.expiresAt.difference(now);
    final next = left.isNegative ? Duration.zero : left;
    setState(() => _left = next);
    if (expired && !_expiredNotified && widget.onExpired != null) {
      _expiredNotified = true;
      widget.onExpired!();
    }
  }

  TransferMessage? _outgoingFromRead() {
    for (final m in ref.read(messageListProvider)) {
      if (m.shareId == widget.shareId && m.isOutgoing) {
        return m;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outgoing = _outgoing();
    final completed = outgoing?.status == TransferMessageStatus.completed;
    final receiving = outgoing?.status == TransferMessageStatus.receiving;

    final mm = _left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _left.inSeconds.remainder(60).toString().padLeft(2, '0');

    final statusText = completed
        ? l10n.transferCompleted
        : receiving
        ? l10n.transferInProgress
        : (_left == Duration.zero
              ? l10n.transferEnded
              : l10n.timeRemaining(mm, ss));

    final statusColor = completed
        ? Colors.green
        : receiving
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.shareRecordTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  statusText,
                  style: AppTextStyles.hint(
                    context,
                  ).copyWith(color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (widget.recipients.isNotEmpty) ...[
              Text(l10n.receiverLabel, style: AppTextStyles.secondary(context)),
              const SizedBox(height: 6),
              _RecipientAvatarStack(devices: widget.recipients),
              const SizedBox(height: 12),
            ],
            Text(
              completed
                  ? l10n.shareAllReceivedHint
                  : receiving
                  ? l10n.shareTransferringHint
                  : l10n.shareWaitAcceptHint,
              style: AppTextStyles.secondary(context),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: completed
                  ? EButton(
                      variant: EButtonVariant.tonal,
                      radius: 99,
                      text: l10n.closeAction,
                      onPressed: widget.onDismissRecord,
                    )
                  : EButton(
                      variant: EButtonVariant.text,
                      destructive: true,
                      radius: 99,
                      text: l10n.cancelSharingAction,
                      onPressed: widget.onCancelSharing,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientAvatarStack extends StatelessWidget {
  final List<LanDevice> devices;

  const _RecipientAvatarStack({required this.devices});

  static const double _size = 28;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: [
        for (final d in devices)
          ClipOval(
            child: Image.asset(
              memojiAssetPath(d.avatar),
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.person,
                size: _size * 0.55,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
