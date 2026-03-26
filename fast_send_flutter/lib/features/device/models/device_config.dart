import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_config.freezed.dart';
part 'device_config.g.dart';

/// memoji 头像总数（assets/images/memoji/1.png ~ 58.png）
const int kMemojiCount = 58;

/// 设备配置模型
@freezed
abstract class DeviceConfig with _$DeviceConfig {
  const factory DeviceConfig({
    required String deviceId,
    required String deviceName,
    required int createdAt,
    /// 头像编号（1 ~ 58，对应 memoji 图片）
    @Default(1) int avatar,
  }) = _DeviceConfig;

  factory DeviceConfig.fromJson(Map<String, dynamic> json) =>
      _$DeviceConfigFromJson(json);
}

/// 根据头像编号获取 asset 路径
String memojiAssetPath(int avatar) =>
    'assets/images/memoji/$avatar.png';
