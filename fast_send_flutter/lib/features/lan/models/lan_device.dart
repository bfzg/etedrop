import 'package:freezed_annotation/freezed_annotation.dart';

part 'lan_device.freezed.dart';
part 'lan_device.g.dart';

@freezed
abstract class LanDevice with _$LanDevice {
  const factory LanDevice({
    required String deviceId,
    required String deviceName,
    required String ip,
    required int port,
    required String os,
    @Default(0) int lastSeen,
    @Default(1) int avatar,
    /// 是否在局域网发现窗口内仍收到心跳（离线条目保留展示，样式置灰）
    @Default(true) bool isOnline,
    /// 长时间未收到对端宣告时的「可疑」态：仍视为在线尝试连接，UI 略灰
    @Default(false) bool isPresenceWeak,
  }) = _LanDevice;

  factory LanDevice.fromJson(Map<String, dynamic> json) => _$LanDeviceFromJson(json);
}
