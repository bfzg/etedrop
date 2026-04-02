import 'package:flutter/material.dart';
import 'dart:io';

import '../../../l10n/app_localizations.dart';
import '../../../styles/styles.dart';

/// 未设置存储目录时的空状态视图
class EmptyStorageView extends StatelessWidget {
  final VoidCallback onSelectDir;

  const EmptyStorageView({super.key, required this.onSelectDir});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              isDesktop ? l10n.storageNotSetTitle : l10n.storagePreparingTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.xs,
            Text(
              isDesktop ? l10n.storageNotSetSubtitle : l10n.storagePreparingSubtitle,
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
                label: Text(l10n.chooseStorageFolder),
              ),
          ],
        ),
      ),
    );
  }
}
