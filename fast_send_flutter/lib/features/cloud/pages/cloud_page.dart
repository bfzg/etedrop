import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/styles.dart';

import '../models/fs_entry.dart';
import '../providers/cloud_provider.dart';
import '../widgets/breadcrumb_nav.dart';
import '../widgets/empty_storage_view.dart';
import '../widgets/file_list_view.dart';
import '../widgets/new_folder_dialog.dart';
import '../../share/widgets/share_dialog.dart';

import '../widgets/file_table_view.dart';

/// 网盘文件管理页面
/// 对应 Electron: src/routes/cloud.tsx → CloudPage
class CloudPage extends ConsumerWidget {
  const CloudPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasStorage = ref.watch(hasStorageDirProvider);
    final storagePath = ref.watch(storageDirPathProvider);
    final fileListAsync = ref.watch(cloudFileListProvider);
    final currentPath = ref.watch(currentPathProvider);
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      appBar: isDesktopLayout
          ? null
          : AppBar(
              title: const Text('网盘'),
              leading: currentPath.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () =>
                          ref.read(currentPathProvider.notifier).navigateUp(),
                    )
                  : null,
              actions: [
                if (hasStorage) ..._buildActions(context, ref, storagePath),
              ],
            ),
      body: !hasStorage
          ? EmptyStorageView(
              onSelectDir: () =>
                  ref.read(fileServiceProvider.notifier).selectStorageDir(),
            )
          : Column(
              children: [
                if (isDesktopLayout)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Row(
                      children: [
                        if (currentPath.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: '返回上一级',
                            onPressed: () => ref
                                .read(currentPathProvider.notifier)
                                .navigateUp(),
                          ),
                        const Spacer(),
                        ..._buildActions(context, ref, storagePath),
                      ],
                    ),
                  ),
                // 面包屑导航
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const BreadcrumbNav(),
                ),
                const Divider(height: 1),
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
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          Gap.md,
                          Text('加载失败: $err'),
                          Gap.md,
                          FilledButton(
                            onPressed: () => ref
                                .read(cloudFileListProvider.notifier)
                                .refresh(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除 "${entry.name}" 吗？${entry.isDirectory ? '\n文件夹内所有内容将被删除。' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
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
    return [
      IconButton(
        icon: const Icon(Icons.create_new_folder_outlined),
        tooltip: '新建文件夹',
        onPressed: () => _showNewFolderDialog(context, ref),
      ),
      IconButton(
        icon: const Icon(Icons.upload_file),
        tooltip: '上传文件',
        onPressed: () => ref.read(cloudFileListProvider.notifier).uploadFiles(),
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: '刷新',
        onPressed: () => ref.read(cloudFileListProvider.notifier).refresh(),
      ),
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'change_dir') {
            ref.read(fileServiceProvider.notifier).selectStorageDir();
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
                      const Text('更换存储目录'),
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
