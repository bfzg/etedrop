import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/local_storage_service.dart';
import '../models/fs_entry.dart';
import '../services/file_service.dart';

part 'cloud_provider.g.dart';

const _storageDirKey = 'cloud_storage_dir';
const _storageDirUserSelectedKey = 'cloud_storage_dir_user_selected';
const _downloadDirKey = 'download_dir';

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
@riverpod
class FileServiceNotifier extends _$FileServiceNotifier {
  @override
  FileService build() {
    final fileService = FileService();
    // 仅当用户明确手动选择过网盘目录时才恢复，默认保持未设置
    final userSelected =
        LocalStorageService.instance.get<bool>(_storageDirUserSelectedKey) ??
        false;
    if (!userSelected) {
      return fileService;
    }

    // 初始化时从本地存储读取网盘目录
    final savedDir = LocalStorageService.instance.get<String>(_storageDirKey);
    if (savedDir != null && savedDir.isNotEmpty) {
      fileService.setStorageDir(savedDir);
    }
    return fileService;
  }

  Future<void> setStorageDir(String path) async {
    final next = FileService();
    next.setStorageDir(path);
    state = next;
    await LocalStorageService.instance.set<String>(_storageDirKey, path);
    await LocalStorageService.instance.set<bool>(_storageDirUserSelectedKey, true);
  }

  Future<String?> selectStorageDir() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择网盘存储目录',
    );
    if (result != null) {
      await setStorageDir(result);
    }
    return result;
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

  Future<String?> selectDownloadDir() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择下载目录',
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

    final entries = await fileService.listFiles(dir: currentPath.isEmpty ? null : currentPath);

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
      final bytes = await File(file.path!).readAsBytes();
      final targetPath = currentPath.isEmpty ? file.name : p.join(currentPath, file.name);
      await fileService.writeFile(targetPath, bytes);
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
        final bytes = await file.readAsBytes();
        final name = p.basename(filePath);
        final targetPath = currentPath.isEmpty ? name : p.join(currentPath, name);
        await fileService.writeFile(targetPath, bytes);
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
