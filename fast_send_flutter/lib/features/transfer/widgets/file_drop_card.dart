import 'package:flutter/material.dart';

import 'package:eddy/styles/styles.dart';
import 'dashed_border_painter.dart';

class FileDropCard extends StatelessWidget {
  final bool isDragging;
  final bool hasSelectedDevices;
  /// 已选设备但均为离线（与 [hasSelectedDevices] 互斥：后者为真时表示至少有一台在线已选）
  final bool selectionOfflineOnly;
  final VoidCallback onPickRequested;

  const FileDropCard({
    super.key,
    required this.isDragging,
    required this.hasSelectedDevices,
    this.selectionOfflineOnly = false,
    required this.onPickRequested,
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
                  isDragging ? '释放以发送分享' : '拖入或点击选择文件',
                  style: AppTextStyles.title(context).copyWith(
                    color: isDragging ? theme.colorScheme.primary : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectionOfflineOnly
                      ? '所选设备当前离线，请等待上线后再发送，或点击头像取消选择'
                      : hasSelectedDevices
                          ? '多选或拖入多个文件后将立即发出分享邀请'
                          : '请先在上方选择接收设备，再选择或拖入文件',
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
