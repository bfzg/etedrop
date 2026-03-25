import 'package:flutter/material.dart';

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
              '空文件夹',
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
  final FileEntryCallback? onTap;
  final FileEntryCallback? onDelete;
  final FileEntryCallback? onShare;

  const _FileListTile({
    required this.entry,
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
      trailing: PopupMenuButton<String>(
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
          if (!entry.isDirectory)
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text('分享'),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                const SizedBox(width: 8),
                Text('删除', style: TextStyle(color: colorScheme.error)),
              ],
            ),
          ),
        ],
      ),
      onTap: () => onTap?.call(entry),
    );
  }
}
