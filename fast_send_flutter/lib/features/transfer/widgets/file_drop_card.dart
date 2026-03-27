import 'package:flutter/material.dart';

import 'package:eddy/styles/styles.dart';
import 'dashed_border_painter.dart';

class FileDropCard extends StatelessWidget {
  final bool isDragging;
  final bool hasSelectedDevices;
  final VoidCallback onPickRequested;
  /// 已选文件数量（多选）；为 null 时不显示该行
  final int? selectedFileCount;
  /// 为 true 时表示只加入待发送队列，拖拽提示为「添加文件」
  final bool addToQueueMode;

  const FileDropCard({
    super.key,
    required this.isDragging,
    required this.hasSelectedDevices,
    required this.onPickRequested,
    this.selectedFileCount,
    this.addToQueueMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isDragging
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return GestureDetector(
      onTap: onPickRequested,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: borderColor,
            strokeWidth: isDragging ? 2.0 : 1.5,
            dashWidth: 6,
            dashGap: 4,
            radius: 14,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 200),
            padding: const EdgeInsets.all(Spacing.xl),
            decoration: BoxDecoration(
              color: isDragging
                  ? theme.colorScheme.primary.withValues(alpha: 0.04)
                  : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDragging ? Icons.file_download : Icons.upload_file_outlined,
                  size: 48,
                  color: isDragging
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  isDragging
                      ? (addToQueueMode ? '释放以添加文件' : '释放以发送文件')
                      : '拖入或点击选择文件',
                  style: AppTextStyles.title(context).copyWith(
                    color: isDragging ? theme.colorScheme.primary : null,
                  ),
                ),
                const SizedBox(height: 6),
                if (selectedFileCount != null)
                  Text(
                    '已选 $selectedFileCount 个文件',
                    style: AppTextStyles.secondary(context),
                  ),
                if (selectedFileCount != null) const SizedBox(height: 4),
                Text(
                  hasSelectedDevices
                      ? '确认设备后点击下方「发起局域网分享」'
                      : '请先在上方选择接收设备',
                  style: AppTextStyles.hint(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
