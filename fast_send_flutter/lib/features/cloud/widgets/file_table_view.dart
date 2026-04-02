import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/file_type_icon.dart';
import '../models/fs_entry.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final dividerColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.15);
        final headerStyle = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: dividerColor)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l10n.columnName, style: headerStyle),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text(l10n.columnModified, style: headerStyle),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(l10n.columnSize, style: headerStyle),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(l10n.columnActions, style: headerStyle),
                      ),
                    ],
                  ),
                ),
                // Rows
                ...entries.map((entry) {
                  return InkWell(
                    onTap: () => onTap(entry),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: dividerColor)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Image.asset(
                                  fileTypePngForEntry(entry),
                                  width: 20,
                                  height: 20,
                                  filterQuality: FilterQuality.high,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Text(FormatUtils.dateTime(entry.mtime)),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              entry.isDirectory
                                  ? '-'
                                  : FormatUtils.fileSize(entry.size),
                            ),
                          ),
                          // 与双 IconButton 同高，避免文件夹行因无按钮变矮
                          SizedBox(
                            width: 100,
                            height: kMinInteractiveDimension,
                            child: entry.isDirectory
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share, size: 18),
                                        tooltip: l10n.shareTooltip,
                                        onPressed: () => onShare(entry),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18),
                                        tooltip: l10n.deleteTooltip,
                                        color: theme.colorScheme.error,
                                        onPressed: () => onDelete(entry),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
