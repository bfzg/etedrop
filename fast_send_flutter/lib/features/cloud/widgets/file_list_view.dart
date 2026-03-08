import 'package:flutter/material.dart';

import '../../../core/utils/format_utils.dart';
import '../models/fs_entry.dart';

/// 获取文件图标
IconData getFileIcon(FsEntry entry) {
  if (entry.isDirectory) return Icons.folder;
  final ext = entry.name.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
    case 'svg':
      return Icons.image;
    case 'mp4':
    case 'avi':
    case 'mov':
    case 'mkv':
    case 'wmv':
      return Icons.video_file;
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'aac':
    case 'ogg':
      return Icons.audio_file;
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'doc':
    case 'docx':
      return Icons.description;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart;
    case 'ppt':
    case 'pptx':
      return Icons.slideshow;
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return Icons.archive;
    case 'txt':
    case 'md':
    case 'log':
      return Icons.text_snippet;
    case 'dart':
    case 'js':
    case 'ts':
    case 'py':
    case 'java':
    case 'go':
    case 'rs':
    case 'c':
    case 'cpp':
    case 'h':
      return Icons.code;
    case 'json':
    case 'xml':
    case 'yaml':
    case 'yml':
    case 'toml':
      return Icons.data_object;
    case 'apk':
    case 'exe':
    case 'dmg':
    case 'msi':
      return Icons.install_desktop;
    default:
      return Icons.insert_drive_file;
  }
}

/// 获取文件图标颜色
Color getFileIconColor(FsEntry entry, ColorScheme colorScheme) {
  if (entry.isDirectory) return colorScheme.primary;
  final ext = entry.name.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
    case 'svg':
      return Colors.orange;
    case 'mp4':
    case 'avi':
    case 'mov':
    case 'mkv':
      return Colors.red;
    case 'mp3':
    case 'wav':
    case 'flac':
      return Colors.purple;
    case 'pdf':
      return Colors.redAccent;
    case 'zip':
    case 'rar':
    case '7z':
      return Colors.amber;
    default:
      return colorScheme.onSurfaceVariant;
  }
}

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
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
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
      leading: Icon(
        getFileIcon(entry),
        color: getFileIconColor(entry, colorScheme),
        size: 32,
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
