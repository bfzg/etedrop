import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../models/fs_entry.dart';

/// 文件系统服务
/// 对应 Electron: src/ipc/fs/handlers.ts
class FileService {
  String _storageDir = '';

  String get storageDir => _storageDir;

  /// 设置存储目录
  /// 对应 Electron: setStorageDir
  void setStorageDir(String path) {
    _storageDir = path;
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
    if (!resolved.startsWith(_storageDir)) {
      throw Exception('路径越界: $relativePath');
    }
    return resolved;
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
      throw FileSystemException(
        '无权限访问该目录，请检查权限或更换存储目录。',
        e.path,
        e.osError,
      );
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 1) {
        throw FileSystemException(
          '无权限访问该目录，请检查权限或更换存储目录。',
          e.path,
          e.osError,
        );
      }
      rethrow;
    }

    final results = <FsEntry>[];

    for (final entity in entries) {
      try {
        final stat = await entity.stat();
        final relPath = p.relative(entity.path, from: rootDir);
        final isDir = entity is Directory;

        results.add(FsEntry(
          path: relPath,
          name: p.basename(entity.path),
          size: isDir ? 0 : stat.size,
          mtime: stat.modified.millisecondsSinceEpoch,
          isDirectory: isDir,
        ));

        if (isDir && recursive) {
          final nested = await _listEntries(entity.path, recursive, rootDir);
          results.addAll(nested);
        }
      } on PathAccessException catch (e) {
        throw FileSystemException(
          '无权限访问该目录，请检查权限或更换存储目录。',
          e.path,
          e.osError,
        );
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode == 1) {
          throw FileSystemException(
            '无权限访问该目录，请检查权限或更换存储目录。',
            e.path,
            e.osError,
          );
        }
        rethrow;
      }
    }

    return results;
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
