import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../styles/styles.dart';

class SendDropArea extends StatefulWidget {
  final VoidCallback onPickRequested;
  final Future<void> Function(String filePath, String fileName, int fileSize)
  onFileDropped;
  /// 是否启用内部 `DropTarget`。
  /// 若外层已经做了全屏拖拽识别，可设为 false 防止重复触发。
  final bool enableDropTarget;

  /// 外部传入的拖拽高亮状态（外层全屏 DropTarget 用）。
  /// 为 null 时使用组件内部 `_isDragging` 状态。
  final bool? isDraggingOverride;

  const SendDropArea({
    super.key,
    required this.onPickRequested,
    required this.onFileDropped,
    this.enableDropTarget = true,
    this.isDraggingOverride,
  });

  @override
  State<SendDropArea> createState() => _SendDropAreaState();
}

class _SendDropAreaState extends State<SendDropArea> {
  bool _isDragging = false;

  String _cleanDroppedPath(String raw) {
    var s = raw.trim();
    if (s.length >= 2) {
      final first = s[0];
      final last = s[s.length - 1];
      final isPairedQuotes = (first == '\'' && last == '\'') || (first == '"' && last == '"');
      if (isPairedQuotes) {
        s = s.substring(1, s.length - 1).trim();
      }
    }

    while (s.isNotEmpty && (s.startsWith('\'') || s.startsWith('"'))) {
      s = s.substring(1).trimLeft();
    }
    while (s.isNotEmpty && (s.endsWith('\'') || s.endsWith('"'))) {
      s = s.substring(0, s.length - 1).trimRight();
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDragging = widget.isDraggingOverride ?? _isDragging;

    final card = GestureDetector(
      onTap: widget.onPickRequested,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 400,
        height: 260,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDragging ? Icons.file_download : Icons.upload_file_outlined,
              size: 64,
              color: isDragging
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            Gap.md,
            Text(
              isDragging ? '释放以上传文件' : '拖入或点击选择文件',
              style: AppTextStyles.title(context).copyWith(
                color: isDragging ? theme.colorScheme.primary : null,
              ),
            ),
            Gap.xs,
            Text('文件将通过分享链接传输', style: AppTextStyles.hint(context)),
          ],
        ),
      ),
    );

    if (!widget.enableDropTarget) return card;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);

        if (details.files.isEmpty) return;
        final file = details.files.first;
        final filePath = _cleanDroppedPath(file.path);
        if (filePath.isEmpty) return;

        File(filePath).length().then(
          (size) => widget.onFileDropped(filePath, p.basename(filePath), size),
        );
      },
      child: card,
    );
  }
}
