// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceConfig _$DeviceConfigFromJson(Map<String, dynamic> json) =>
    _DeviceConfig(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      avatar: (json['avatar'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$DeviceConfigToJson(_DeviceConfig instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'createdAt': instance.createdAt,
      'avatar': instance.avatar,
    };
