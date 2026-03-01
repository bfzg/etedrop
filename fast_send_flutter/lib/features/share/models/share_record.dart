import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_record.freezed.dart';
part 'share_record.g.dart';

/// 分享记录模型
/// 对应 Electron: src/ipc/share/handlers.ts → ShareRecord interface
@freezed
abstract class ShareRecord with _$ShareRecord {
  const factory ShareRecord({
    /// 分享码（8位十六进制）
    required String code,

    /// 文件相对路径
    required String path,

    /// 文件名
    required String fileName,

    /// 文件大小（字节）
    required int size,

    /// SHA256 哈希后的密码，null 表示无密码
    String? passwordHash,

    /// 创建时间戳（毫秒）
    required int createdAt,

    /// 过期时间戳（毫秒），null 表示永不过期
    int? expiresAt,
  }) = _ShareRecord;

  factory ShareRecord.fromJson(Map<String, dynamic> json) =>
      _$ShareRecordFromJson(json);
}

/// 分享信息（对外暴露，不含密码哈希）
/// 对应 Electron: src/ipc/share/handlers.ts → ShareInfo interface
@freezed
abstract class ShareInfo with _$ShareInfo {
  const factory ShareInfo({
    required String code,
    required String path,
    required String fileName,
    required int size,
    required bool hasPassword,
    required int createdAt,
    int? expiresAt,
  }) = _ShareInfo;

  factory ShareInfo.fromJson(Map<String, dynamic> json) =>
      _$ShareInfoFromJson(json);
}
