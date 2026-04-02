import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/local_storage_service.dart';
import '../../../core/utils/resumable_transfer.dart';
import '../cloud_storage_prefs.dart';
import '../models/fs_entry.dart';
import '../services/file_service.dart';
import '../services/macos_cloud_storage_access.dart';

part 'cloud_provider.g.dart';

const _downloadDirKey = 'download_dir';
const _mobileDefaultCloudSubdir = 'eddy';

bool _isDesktopPlatform() {
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

Future<String> _defaultDownloadDir() async {
  if (Platform.isAndroid) {
    final dir = await getExternalStorageDirectory();
    if (dir != null) return dir.path;
    return (await getApplicationDocumentsDirectory()).path;
  }

  if (Platform.isIOS) {
    return (await getApplicationDocumentsDirectory()).path;
  }

  // macOS / Windows / Linux
  final downloads = await getDownloadsDirectory();
  if (downloads != null) return downloads.path;
  return (await getApplicationDocumentsDirectory()).path;
}

/// 文件服务单例 Provider
///
/// keepAlive：避免 autoDispose 在首屏仅被 `ref.read`（如 LanManager 初始化）后释放，
/// 与网盘列表异步扫描竞态，表现为长时间加载后误报无权限；设置里重选同一路径会新建实例因而「立刻好」。
@Riverpod(keepAlive: true)
class FileServiceNotifier extends _$FileServiceNotifier {
  Future<void>? _mobileInitFuture;

  @override
  FileService build() {
    final fileService = FileService();

    // Mobile: always use an app-owned directory (scoped storage / iOS sandbox).
    // Avoid asking users to pick arbitrary folders which may be unwritable.
    if (Platform.isAndroid || Platform.isIOS) {
      // Kick off init once; when done we update state so UI stops showing "preparing".
      _mobileInitFuture ??= _initMobileDefaultStorageDir();
      return fileService;
    }

    // 仅当用户明确手动选择过网盘目录时才恢复，默认保持未设置
    final userSelected =
        LocalStorageService.instance.get<bool>(kCloudStorageDirUserSelectedKey) ??
        false;
    if (!userSelected) {
      return fileService;
    }

    // macOS 沙盒：须在 main 中已通过书签 startAccessing，此处优先使用恢复后的路径
    String? dir;
    if (Platform.isMacOS && MacosCloudStorageAccess.scopedStorageDir != null) {
      dir = MacosCloudStorageAccess.scopedStorageDir;
    } else {
      dir = LocalStorageService.instance.get<String>(kCloudStorageDirKey);
    }
    if (dir != null && dir.isNotEmpty) {
      fileService.setStorageDir(dir);
    }
    return fileService;
  }

  Future<void> setStorageDir(String path) async {
    final next = FileService();
    next.setStorageDir(path);
    state = next;
    await LocalStorageService.instance.set<String>(kCloudStorageDirKey, path);
    await LocalStorageService.instance.set<bool>(
      kCloudStorageDirUserSelectedKey,
      true,
    );
    await MacosCloudStorageAccess.persistBookmarkForPath(path);
  }

  Future<String?> selectStorageDir({String? dialogTitle}) async {
    // Mobile: don't prompt for directory selection; keep storage in app-owned dir.
    if (!_isDesktopPlatform()) {
      _mobileInitFuture ??= _initMobileDefaultStorageDir();
      await _mobileInitFuture;
      return state.storageDir;
    }

    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle,
    );
    if (result != null) {
      await setStorageDir(result);
    }
    return result;
  }

  Future<void> _initMobileDefaultStorageDir() async {
    try {
      final base = Platform.isAndroid
          ? (await getExternalStorageDirectory())?.path
          : (await getApplicationDocumentsDirectory()).path;
      final root = base ?? (await getApplicationDocumentsDirectory()).path;
      final target = p.join(root, _mobileDefaultCloudSubdir);
      await setStorageDir(target);
      await state.ensureStorageDir();
    } catch (e) {
      // As a last resort, keep storageDir empty; UI will show error/empty state.
      debugPrint('Init mobile storage dir failed: $e');
    }
  }
}

/// 下载目录（用于接收文件保存位置）
@riverpod
class DownloadDir extends _$DownloadDir {
  @override
  FutureOr<String> build() async {
    final saved = LocalStorageService.instance.get<String>(_downloadDirKey);
    if (saved != null && saved.isNotEmpty) return saved;

    final def = await _defaultDownloadDir();
    await LocalStorageService.instance.set<String>(_downloadDirKey, def);
    return def;
  }

  Future<void> setDownloadDir(String path) async {
    state = AsyncData(path);
    await LocalStorageService.instance.set<String>(_downloadDirKey, path);
  }

  Future<String?> selectDownloadDir({String? dialogTitle}) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle,
    );
    if (result != null) {
      await setDownloadDir(result);
    }
    return result;
  }
}

/// 当前浏览路径状态
@riverpod
class CurrentPath extends _$CurrentPath {
  @override
  String build() => '';

  void navigate(String path) {
    state = path;
  }

  void navigateUp() {
    if (state.isEmpty) return;
    final parent = p.dirname(state);
    state = (parent == '.' || parent == state) ? '' : parent;
  }

  void navigateToRoot() {
    state = '';
  }
}

/// 文件列表状态
@riverpod
class CloudFileList extends _$CloudFileList {
  @override
  FutureOr<List<FsEntry>> build() async {
    final fileService = ref.watch(fileServiceProvider);
    final currentPath = ref.watch(currentPathProvider);

    if (fileService.storageDir.isEmpty) {
      return [];
    }

    final entries = await fileService.listFiles(
      dir: currentPath.isEmpty ? null : currentPath,
    );

    // 排序：文件夹在前，然后按名称排序
    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  /// 刷新文件列表
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// 创建文件夹
  Future<void> createFolder(String name) async {
    final fileService = ref.read(fileServiceProvider);
    final currentPath = ref.read(currentPathProvider);
    final folderPath = currentPath.isEmpty ? name : p.join(currentPath, name);
    await fileService.createDir(folderPath);
    ref.invalidateSelf();
  }

  /// 删除文件/文件夹
  Future<void> deleteEntry(FsEntry entry) async {
    final fileService = ref.read(fileServiceProvider);
    await fileService.deleteFile(entry.path, recursive: entry.isDirectory);
    ref.invalidateSelf();
  }

  /// 上传文件（通过 FilePicker 选择）
  Future<void> uploadFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    final fileService = ref.read(fileServiceProvider);
    final currentPath = ref.read(currentPathProvider);

    for (final file in result.files) {
      if (file.path == null) continue;
      final targetPath = currentPath.isEmpty
          ? file.name
          : p.join(currentPath, file.name);
      try {
        await fileService.importLocalFileResumable(targetPath, file.path!);
      } on ResumableTransferException catch (e) {
        if (e.message != '传输已取消') rethrow;
      }
    }

    ref.invalidateSelf();
  }

  /// 上传拖拽的文件
  Future<void> uploadDroppedFiles(List<String> paths) async {
    final fileService = ref.read(fileServiceProvider);
    final currentPath = ref.read(currentPathProvider);

    for (final filePath in paths) {
      final file = File(filePath);
      if (await file.exists()) {
        final name = p.basename(filePath);
        final targetPath = currentPath.isEmpty
            ? name
            : p.join(currentPath, name);
        try {
          await fileService.importLocalFileResumable(targetPath, filePath);
        } on ResumableTransferException catch (e) {
          if (e.message != '传输已取消') rethrow;
        }
      }
    }

    ref.invalidateSelf();
  }
}

/// 存储目录是否已设置
@riverpod
bool hasStorageDir(Ref ref) {
  final fileService = ref.watch(fileServiceProvider);
  return fileService.storageDir.isNotEmpty;
}

/// 获取存储目录路径
@riverpod
String storageDirPath(Ref ref) {
  final fileService = ref.watch(fileServiceProvider);
  return fileService.storageDir;
}

/// 面包屑路径段
@riverpod
List<String> breadcrumbSegments(Ref ref) {
  final currentPath = ref.watch(currentPathProvider);
  if (currentPath.isEmpty) return [];
  return p.split(currentPath);
}
