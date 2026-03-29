import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/resumable_transfer.dart';
import '../models/fs_entry.dart';

/// 云盘列表不展示以 `.` 开头的条目（如 `.git`、`.DS_Store`、`.svn`）及未完成上传的 `.fastsend.part`。
bool _isHiddenCloudEntryName(String name) =>
    name.isNotEmpty &&
    (name.startsWith('.') ||
        name.endsWith(ResumableTransferPaths.cloudPartialSuffix));

/// 文件系统服务
/// 对应 Electron: src/ipc/fs/handlers.ts
class FileService {
  String _storageDir = '';

  String get storageDir => _storageDir;

  /// 与系统文件选择器、符号链接解析后的路径对齐，避免 `startsWith` 误判与重复扫描异常。
  static String normalizeStorageRoot(String path) {
    var s = path.trim();
    if (s.isEmpty) return s;
    s = p.normalize(s);
    try {
      final d = Directory(s);
      if (d.existsSync()) {
        return p.normalize(d.resolveSymbolicLinksSync());
      }
    } catch (_) {}
    return s;
  }

  /// 设置存储目录
  /// 对应 Electron: setStorageDir
  void setStorageDir(String path) {
    _storageDir = normalizeStorageRoot(path);
  }

  /// 确保存储目录存在
  /// 对应 Electron: ensureStorageDir
  Future<void> ensureStorageDir() async {
    if (_storageDir.isEmpty) return;
    final dir = Directory(_storageDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 解析相对路径为绝对路径（防路径穿越）
  /// 对应 Electron: resolveStoragePath
  String resolveStoragePath(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return _storageDir;
    }
    final resolved = p.normalize(p.join(_storageDir, relativePath));
    if (!_isResolvedUnderStorageRoot(resolved)) {
      throw Exception('路径越界: $relativePath');
    }
    return resolved;
  }

  bool _isResolvedUnderStorageRoot(String resolved) {
    final r = p.normalize(resolved);
    final root = p.normalize(_storageDir);
    if (Platform.isWindows) {
      final rl = r.toLowerCase();
      final rtl = root.toLowerCase();
      return rl == rtl || rl.startsWith('$rtl\\') || rl.startsWith('$rtl/');
    }
    return r == root || r.startsWith('$root${p.separator}');
  }

  /// 列出文件
  /// 对应 Electron: listFiles / listEntries
  Future<List<FsEntry>> listFiles({String? dir, bool recursive = false}) async {
    await ensureStorageDir();
    final targetDir = resolveStoragePath(dir);
    return _listEntries(targetDir, recursive, _storageDir);
  }

  Future<List<FsEntry>> _listEntries(
    String currentDir,
    bool recursive,
    String rootDir,
  ) async {
    final directory = Directory(currentDir);
    if (!await directory.exists()) {
      throw FileSystemException('目录不存在', currentDir);
    }

    List<FileSystemEntity> entries;
    try {
      entries = await directory.list(followLinks: false).toList();
    } on PathAccessException catch (e) {
      throw FileSystemException('无权限访问该目录，请检查权限或更换存储目录。', e.path, e.osError);
    } on FileSystemException catch (e) {
      if (_isLikelyAccessDenied(e)) {
        throw FileSystemException('无权限访问该目录，请检查权限或更换存储目录。', e.path, e.osError);
      }
      rethrow;
    }

    final results = <FsEntry>[];

    for (final entity in entries) {
      final name = p.basename(entity.path);
      if (_isHiddenCloudEntryName(name)) continue;

      try {
        final stat = await entity.stat();
        final relPath = p.relative(entity.path, from: rootDir);
        final isDir = entity is Directory;

        results.add(
          FsEntry(
            path: relPath,
            name: name,
            size: isDir ? 0 : stat.size,
            mtime: stat.modified.millisecondsSinceEpoch,
            isDirectory: isDir,
          ),
        );

        if (isDir && recursive) {
          final nested = await _listEntries(entity.path, recursive, rootDir);
          results.addAll(nested);
        }
      } on PathAccessException catch (e) {
        if (kDebugMode) {
          debugPrint('Cloud list: skip entry (access) ${entity.path} ($e)');
        }
        continue;
      } on FileSystemException catch (e) {
        if (_isLikelyAccessDenied(e)) {
          if (kDebugMode) {
            debugPrint('Cloud list: skip entry (denied) ${entity.path} ($e)');
          }
          continue;
        }
        rethrow;
      }
    }

    return results;
  }

  /// Windows 上「拒绝访问」多为 error 5；Unix 上常见为 EPERM(1)/EACCES(13)。勿用 1 通杀各平台以免误判。
  static bool _isLikelyAccessDenied(FileSystemException e) {
    final c = e.osError?.errorCode;
    if (c == null) return false;
    if (Platform.isWindows) {
      return c == 5;
    }
    return c == 1 || c == 13;
  }

  /// 读取文件
  /// 对应 Electron: readFile
  Future<Uint8List> readFile(String relativePath) async {
    await ensureStorageDir();
    final resolved = resolveStoragePath(relativePath);
    return File(resolved).readAsBytes();
  }

  /// 写入文件
  /// 对应 Electron: writeFile
  Future<void> writeFile(
    String relativePath,
    Uint8List data, {
    bool overwrite = true,
    bool mkdirs = true,
  }) async {
    await ensureStorageDir();
    final resolved = resolveStoragePath(relativePath);

    if (mkdirs) {
      await Directory(p.dirname(resolved)).create(recursive: true);
    }

    if (!overwrite && await File(resolved).exists()) {
      throw Exception('文件已存在: $relativePath');
    }

    await File(resolved).writeAsBytes(data);
  }

  /// 从本机路径流式导入到云盘目录，支持大文件与断点续传（同一路径下保留 `*.fastsend.part`）。
  ///
  /// 中断后再次导入同一 [relativePath] 会从 `.fastsend.part` 已写字节继续；完成后替换为正式文件。
  Future<void> importLocalFileResumable(
    String relativePath,
    String absoluteSourcePath, {
    void Function(int written, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    await ensureStorageDir();
    final src = File(absoluteSourcePath);
    if (!await src.exists()) {
      throw FileSystemException('源文件不存在', absoluteSourcePath);
    }
    final total = await src.length();
    final resolved = resolveStoragePath(relativePath);
    final partPath = '$resolved${ResumableTransferPaths.cloudPartialSuffix}';
    final partFile = File(partPath);

    var offset = 0;
    if (await partFile.exists()) {
      offset = await partFile.length();
    }
    if (offset > total) {
      await partFile.delete();
      offset = 0;
    }

    if (offset == total && total > 0) {
      final dest = File(resolved);
      if (await dest.exists()) {
        await dest.delete();
      }
      await partFile.rename(resolved);
      onProgress?.call(total, total);
      return;
    }

    await Directory(p.dirname(resolved)).create(recursive: true);
    final stream = src.openRead(offset);
    final sink = offset == 0
        ? partFile.openWrite(mode: FileMode.write)
        : partFile.openWrite(mode: FileMode.append);

    var written = offset;
    var sinceCheck = 0;
    const checkEvery = 256 * 1024;

    try {
      await for (final chunk in stream) {
        if (shouldCancel?.call() == true) {
          await sink.close();
          throw ResumableTransferException('传输已取消');
        }
        sink.add(chunk);
        written += chunk.length;
        sinceCheck += chunk.length;
        onProgress?.call(written, total);
        if (sinceCheck >= checkEvery) {
          sinceCheck = 0;
          if (shouldCancel?.call() == true) {
            await sink.close();
            throw ResumableTransferException('传输已取消');
          }
        }
      }
      await sink.close();
    } catch (e) {
      try {
        await sink.close();
      } catch (_) {}
      rethrow;
    }

    final len = await partFile.length();
    if (len != total) {
      throw StateError('云盘写入长度不符: 期望 $total，实际 $len');
    }
    final dest = File(resolved);
    if (await dest.exists()) {
      await dest.delete();
    }
    await partFile.rename(resolved);
    onProgress?.call(total, total);
  }

  /// 删除文件或文件夹
  /// 对应 Electron: deleteFile
  Future<void> deleteFile(String relativePath, {bool recursive = false}) async {
    await ensureStorageDir();
    final resolved = resolveStoragePath(relativePath);
    final type = await FileSystemEntity.type(resolved);

    if (type == FileSystemEntityType.directory) {
      await Directory(resolved).delete(recursive: recursive);
    } else {
      await File(resolved).delete();
    }
  }

  /// 创建文件夹
  /// 对应 Electron: createDir
  Future<void> createDir(String relativePath) async {
    await ensureStorageDir();
    final resolved = resolveStoragePath(relativePath);
    await Directory(resolved).create(recursive: true);
  }
}
