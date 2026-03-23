import 'package:flutter/material.dart';

import '../../../core/utils/format_utils.dart';
import '../models/fs_entry.dart';
import 'file_list_view.dart' show getFileIcon;

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
                              : getFileIcon(entry),
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
                  DataCell(Text(FormatUtils.dateTime(entry.mtime))),
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

}
