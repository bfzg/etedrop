// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Contact _$ContactFromJson(Map<String, dynamic> json) => _Contact(
  userId: json['userId'] as String,
  displayName: json['displayName'] as String,
  avatar: (json['avatar'] as num?)?.toInt() ?? 1,
  transport:
      $enumDecodeNullable(_$ContactTransportEnumMap, json['transport']) ??
      ContactTransport.lan,
  ip: json['ip'] as String?,
  port: (json['port'] as num?)?.toInt(),
  os: json['os'] as String?,
  isOnline: json['isOnline'] as bool? ?? false,
  autoDiscovered: json['autoDiscovered'] as bool? ?? true,
  addedAt: (json['addedAt'] as num).toInt(),
  lastSeenAt: (json['lastSeenAt'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ContactToJson(_Contact instance) => <String, dynamic>{
  'userId': instance.userId,
  'displayName': instance.displayName,
  'avatar': instance.avatar,
  'transport': _$ContactTransportEnumMap[instance.transport]!,
  'ip': instance.ip,
  'port': instance.port,
  'os': instance.os,
  'isOnline': instance.isOnline,
  'autoDiscovered': instance.autoDiscovered,
  'addedAt': instance.addedAt,
  'lastSeenAt': instance.lastSeenAt,
};

const _$ContactTransportEnumMap = {
  ContactTransport.lan: 'lan',
  ContactTransport.webrtc: 'webrtc',
};
