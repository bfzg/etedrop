// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lan_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LanDevice _$LanDeviceFromJson(Map<String, dynamic> json) => _LanDevice(
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  ip: json['ip'] as String,
  port: (json['port'] as num).toInt(),
  os: json['os'] as String,
  lastSeen: (json['lastSeen'] as num?)?.toInt() ?? 0,
  avatar: (json['avatar'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$LanDeviceToJson(_LanDevice instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'ip': instance.ip,
      'port': instance.port,
      'os': instance.os,
      'lastSeen': instance.lastSeen,
      'avatar': instance.avatar,
    };
