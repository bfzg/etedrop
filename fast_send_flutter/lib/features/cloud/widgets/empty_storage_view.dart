import 'package:flutter/material.dart';
import 'dart:io';

import '../../../styles/styles.dart';

/// 未设置存储目录时的空状态视图
class EmptyStorageView extends StatelessWidget {
  final VoidCallback onSelectDir;

  const EmptyStorageView({super.key, required this.onSelectDir});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            Gap.md,
            Text(
              isDesktop ? '尚未设置存储目录' : '正在准备存储目录',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.xs,
            Text(
              isDesktop ? '请选择一个文件夹作为网盘存储目录' : '手机端将自动使用应用专用目录保存文件',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            Gap.md,
            if (isDesktop)
              FilledButton.icon(
                onPressed: onSelectDir,
                icon: const Icon(Icons.folder_open),
                label: const Text('选择存储目录'),
              ),
          ],
        ),
      ),
    );
  }
}
