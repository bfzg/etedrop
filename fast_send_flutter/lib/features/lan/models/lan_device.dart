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
  }) = _LanDevice;

  factory LanDevice.fromJson(Map<String, dynamic> json) => _$LanDeviceFromJson(json);
}
