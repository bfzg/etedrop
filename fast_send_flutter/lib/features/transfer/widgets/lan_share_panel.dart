import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/styles.dart';
import '../../device/models/device_config.dart';
import '../../lan/models/lan_device.dart';
import '../../lan/providers/lan_provider.dart';
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

  String _linkText() {
    final port = ref.read(lanManagerProvider.notifier).localHttpPort;
    return 'lan-share://${widget.shareId}?port=$port';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outgoing = _outgoing();
    final completed = outgoing?.status == TransferMessageStatus.completed;
    final receiving = outgoing?.status == TransferMessageStatus.receiving;

    final mm = _left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _left.inSeconds.remainder(60).toString().padLeft(2, '0');

    final statusText = completed
        ? '已完成'
        : receiving
            ? '传输中'
            : (_left == Duration.zero ? '已结束' : '剩余 $mm:$ss');

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
                  '分享记录',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  statusText,
                  style: AppTextStyles.hint(context).copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (widget.recipients.isNotEmpty) ...[
              Text('接收方', style: AppTextStyles.secondary(context)),
              const SizedBox(height: 6),
              _RecipientAvatarStack(devices: widget.recipients),
              const SizedBox(height: 12),
            ],
            SelectableText(
              _linkText(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              completed
                  ? '对方已成功接收本次分享的全部文件。'
                  : receiving
                      ? '正在向对方设备传输文件，请保持本应用在前台或勿断网。'
                      : '对端需在消息里「接收」后才会开始传输；无人接受 2 分钟后自动取消。',
              style: AppTextStyles.secondary(context),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _linkText()));
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
                    }
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制'),
                ),
                const SizedBox(width: 8),
                if (completed)
                  FilledButton.tonal(
                    onPressed: widget.onDismissRecord,
                    child: const Text('关闭'),
                  )
                else
                  TextButton(
                    onPressed: widget.onCancelSharing,
                    child: Text(
                      '取消分享',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
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
  static const double _overlap = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = devices.length > 8 ? 8 : devices.length;
    final extra = devices.length - n;
    final width = n <= 1
        ? _size
        : _size + (n - 1) * _overlap + (extra > 0 ? 12 : 0);

    return SizedBox(
      height: _size + 4,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < n; i++)
            Positioned(
              left: i * _overlap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    memojiAssetPath(devices[i].avatar),
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
              ),
            ),
          if (extra > 0)
            Positioned(
              left: (n - 1) * _overlap + 6,
              child: CircleAvatar(
                radius: _size / 2,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  '+$extra',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
