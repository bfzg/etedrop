import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../styles/styles.dart';

import '../models/fs_entry.dart';
import '../providers/cloud_provider.dart';
import '../widgets/breadcrumb_nav.dart';
import '../widgets/empty_storage_view.dart';
import '../widgets/file_list_view.dart';
import '../widgets/new_folder_dialog.dart';
import '../../share/widgets/share_dialog.dart';
import '../../../core/utils/access_utils.dart';
import '../../../widgets/ui/e_button.dart';
import '../../../widgets/ui/e_dialog.dart';
import '../widgets/file_table_view.dart';

/// 网盘文件管理页面
/// 对应 Electron: src/routes/cloud.tsx → CloudPage
class CloudPage extends ConsumerWidget {
  const CloudPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasStorage = ref.watch(hasStorageDirProvider);
    final storagePath = ref.watch(storageDirPathProvider);
    final fileListAsync = ref.watch(cloudFileListProvider);
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;
    final isDesktopPlatform = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    final showActions = hasStorage;

    return Scaffold(
      appBar: AppBar(
        actions: !isDesktopLayout && showActions
            ? _buildActions(context, ref, storagePath)
            : null,
        title: Row(
          children: [
            const Expanded(child: BreadcrumbNav()),

            if (isDesktopLayout && showActions)
              ..._buildActions(context, ref, storagePath),
          ],
        ),
      ),
      body: !hasStorage
          ? EmptyStorageView(
              // Mobile uses an app-owned directory automatically.
              onSelectDir: isDesktopPlatform
                  ? () => ref.read(fileServiceProvider.notifier).selectStorageDir(
                        dialogTitle: l10n.pickCloudStorageTitle,
                      )
                  : () {},
            )
          : Column(
              children: [
                // 文件列表
                Expanded(
                  child: fileListAsync.when(
                    data: (entries) => RefreshIndicator(
                      onRefresh: () =>
                          ref.read(cloudFileListProvider.notifier).refresh(),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // 宽屏使用表格视图，窄屏使用列表视图
                          if (constraints.maxWidth > 600) {
                            return FileTableView(
                              entries: entries,
                              onTap: (entry) => _handleTap(ref, entry),
                              onDelete: (entry) =>
                                  _handleDelete(context, ref, entry),
                              onShare: (entry) =>
                                  _handleShare(context, ref, entry),
                            );
                          }
                          return FileListView(
                            entries: entries,
                            onTap: (entry) => _handleTap(ref, entry),
                            onDelete: (entry) =>
                                _handleDelete(context, ref, entry),
                            onShare: (entry) =>
                                _handleShare(context, ref, entry),
                          );
                        },
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) {
                      final message =
                          err is FileSystemException && err.message.isNotEmpty
                          ? err.message
                          : err.toString();
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              Gap.md,
                              Text(
                                l10n.loadFailed,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Gap.md,
                              FilledButton(
                                onPressed: () => ref
                                    .read(cloudFileListProvider.notifier)
                                    .refresh(),
                                child: Text(l10n.retry),
                              ),
                              if (Platform.isMacOS) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () async {
                                    await openMacOsFullDiskAccessSettings();
                                  },
                                  icon: const Icon(Icons.settings, size: 18),
                                  label: Text(l10n.openSystemSettingsForAccess),
                                ),
                              ],
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => ref
                                    .read(fileServiceProvider.notifier)
                                    .selectStorageDir(
                                      dialogTitle: l10n.pickCloudStorageTitle,
                                    ),
                                child: Text(l10n.changeStorageDirectory),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _handleTap(WidgetRef ref, FsEntry entry) {
    if (entry.isDirectory) {
      ref.read(currentPathProvider.notifier).navigate(entry.path);
    }
  }

  void _showNewFolderDialog(BuildContext context, WidgetRef ref) {
    NewFolderDialog.show(
      context,
      (name) => ref.read(cloudFileListProvider.notifier).createFolder(name),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    FsEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => EDialog.alert(
        title: Text(l10n.confirmDelete),
        content: Text(
          l10n.deleteEntryConfirm(
            entry.name,
            entry.isDirectory ? l10n.deleteFolderSuffix : '',
          ),
        ),
        actions: [
          EButton(
            text: l10n.cancel,
            variant: EButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          EButton(
            text: l10n.deleteAction,
            variant: EButtonVariant.danger,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cloudFileListProvider.notifier).deleteEntry(entry);
    }
  }

  void _handleShare(BuildContext context, WidgetRef ref, FsEntry entry) {
    ShareDialog.show(
      context,
      relativePath: entry.path,
      fileName: entry.name,
      fileSize: entry.size,
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    String storagePath,
  ) {
    final l10n = AppLocalizations.of(context)!;
    const barBtnStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(36, 36)),
      padding: WidgetStatePropertyAll(EdgeInsets.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return [
      IconButton(
        style: barBtnStyle,
        iconSize: 20,
        icon: const Icon(Icons.create_new_folder_outlined),
        tooltip: l10n.newFolderTooltip,
        onPressed: () => _showNewFolderDialog(context, ref),
      ),
      IconButton(
        style: barBtnStyle,
        iconSize: 20,
        icon: const Icon(Icons.upload_file),
        tooltip: l10n.uploadFileTooltip,
        onPressed: () => ref.read(cloudFileListProvider.notifier).uploadFiles(),
      ),
      IconButton(
        style: barBtnStyle,
        iconSize: 20,
        icon: const Icon(Icons.refresh),
        tooltip: l10n.refreshTooltip,
        onPressed: () => ref.read(cloudFileListProvider.notifier).refresh(),
      ),
      PopupMenuButton<String>(
        iconSize: 20,
        icon: Icon(
          Icons.more_vert,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onSelected: (value) {
          if (value == 'change_dir') {
            ref.read(fileServiceProvider.notifier).selectStorageDir(
                  dialogTitle: l10n.pickCloudStorageTitle,
                );
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'change_dir',
            child: Row(
              children: [
                const Icon(Icons.folder_open, size: 18),
                Gap.md,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.changeStorageDirectory),
                      Text(
                        storagePath,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}
