import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fs_entry.dart';
import '../../../core/utils/format_utils.dart';

class FileTableView extends StatelessWidget {
  final List<FsEntry> entries;
  final Function(FsEntry) onTap;
  final Function(FsEntry) onDelete;
  final Function(FsEntry) onShare;

  const FileTableView({
    super.key,
    required this.entries,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open,
                size: 80,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('空文件夹',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
            columns: const [
              DataColumn(label: Text('名称')),
              DataColumn(label: Text('修改时间')),
              DataColumn(label: Text('大小')),
              DataColumn(label: Text('操作')),
            ],
            rows: entries.map((entry) {
              return DataRow(
                onSelectChanged: (_) => onTap(entry),
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.isDirectory
                              ? Icons.folder
                              : _getFileIcon(entry.name),
                          color: entry.isDirectory
                              ? Colors.amber
                              : theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            entry.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(_formatTime(entry.mtime))),
                  DataCell(Text(entry.isDirectory ? '-' : FormatUtils.fileSize(entry.size))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share, size: 18),
                          tooltip: '分享',
                          onPressed: () => onShare(entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          tooltip: '删除',
                          color: theme.colorScheme.error,
                          onPressed: () => onDelete(entry),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.movie;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }


  String _formatTime(int mtime) {
    final date = DateTime.fromMillisecondsSinceEpoch(mtime);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
}
