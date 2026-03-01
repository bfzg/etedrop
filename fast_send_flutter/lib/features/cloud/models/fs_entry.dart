import 'package:freezed_annotation/freezed_annotation.dart';

part 'fs_entry.freezed.dart';
part 'fs_entry.g.dart';

/// 文件系统条目模型
/// 对应 Electron: src/ipc/fs/handlers.ts → FsEntry interface
@freezed
abstract class FsEntry with _$FsEntry {
  const factory FsEntry({
    /// 相对于存储根目录的路径
    required String path,

    /// 文件/文件夹名称
    required String name,

    /// 文件大小（字节），文件夹为 0
    required int size,

    /// 最后修改时间（毫秒时间戳）
    required int mtime,

    /// 是否为文件夹
    required bool isDirectory,
  }) = _FsEntry;

  factory FsEntry.fromJson(Map<String, dynamic> json) =>
      _$FsEntryFromJson(json);
}
