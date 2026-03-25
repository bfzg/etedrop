import 'package:flutter/material.dart';

import '../../../core/utils/format_utils.dart';
import '../../../styles/styles.dart';

class SendSharedView extends StatelessWidget {
  final String? fileName;
  final int? fileSize;
  final String? shareLink;
  final VoidCallback onCopyLink;
  final VoidCallback onCancelShare;
  final VoidCallback onShareNew;

  const SendSharedView({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.shareLink,
    required this.onCopyLink,
    required this.onCancelShare,
    required this.onShareNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          Gap.md,
          Text(
            '分享已创建',
            style: AppTextStyles.completeTitle(context),
          ),
          Gap.xs,
          if (fileName != null)
            Text(
              '$fileName (${FormatUtils.fileSize(fileSize ?? 0)})',
              style: AppTextStyles.hint(context),
            ),
          Gap.lg,
          if (shareLink != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      shareLink!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: '复制链接',
                    onPressed: onCopyLink,
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              '请先连接设备后才能生成分享链接',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
          Gap.xl,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: onCancelShare,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('取消分享'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              ),
              Gap.h(Spacing.buttonGap),
              FilledButton.icon(
                onPressed: onShareNew,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('分享新文件'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

