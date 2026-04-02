import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/file_type_icon.dart';
import '../models/fs_entry.dart';

/// 文件列表项回调
typedef FileEntryCallback = void Function(FsEntry entry);

/// 文件列表视图
/// 对应 Electron: src/components/cloud/file-list.tsx
class FileListView extends StatelessWidget {
  final List<FsEntry> entries;
  final FileEntryCallback? onTap;
  final FileEntryCallback? onDelete;
  final FileEntryCallback? onShare;

  const FileListView({
    super.key,
    required this.entries,
    this.onTap,
    this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emptyFolder,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.12)),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _FileListTile(
          entry: entry,
          l10n: l10n,
          onTap: onTap,
          onDelete: onDelete,
          onShare: onShare,
        );
      },
    );
  }
}

class _FileListTile extends StatelessWidget {
  final FsEntry entry;
  final AppLocalizations l10n;
  final FileEntryCallback? onTap;
  final FileEntryCallback? onDelete;
  final FileEntryCallback? onShare;

  const _FileListTile({
    required this.entry,
    required this.l10n,
    this.onTap,
    this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Image.asset(
        fileTypePngForEntry(entry),
        width: 32,
        height: 32,
        filterQuality: FilterQuality.high,
      ),
      title: Text(
        entry.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15),
      ),
      subtitle: Text(
        entry.isDirectory
            ? FormatUtils.dateTime(entry.mtime)
            : '${FormatUtils.fileSize(entry.size)}  ·  ${FormatUtils.dateTime(entry.mtime)}',
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      trailing: entry.isDirectory
          ? const SizedBox(
              width: 48,
              height: 48,
            )
          : PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    onDelete?.call(entry);
                    break;
                  case 'share':
                    onShare?.call(entry);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      const Icon(Icons.share, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.shareAction),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Text(l10n.deleteAction, style: TextStyle(color: colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
      onTap: () => onTap?.call(entry),
    );
  }
}
