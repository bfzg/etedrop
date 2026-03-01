import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_config.freezed.dart';
part 'device_config.g.dart';

/// 设备配置模型
/// 对应 Electron: src/main/device-manager.ts → DeviceConfig interface
@freezed
abstract class DeviceConfig with _$DeviceConfig {
  const factory DeviceConfig({
    /// 设备唯一标识（UUID）
    required String deviceId,

    /// 设备名称（默认为主机名）
    required String deviceName,

    /// 创建时间戳（毫秒）
    required int createdAt,
  }) = _DeviceConfig;

  factory DeviceConfig.fromJson(Map<String, dynamic> json) =>
      _$DeviceConfigFromJson(json);
}
