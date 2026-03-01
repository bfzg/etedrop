// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShareRecord _$ShareRecordFromJson(Map<String, dynamic> json) => _ShareRecord(
  code: json['code'] as String,
  path: json['path'] as String,
  fileName: json['fileName'] as String,
  size: (json['size'] as num).toInt(),
  passwordHash: json['passwordHash'] as String?,
  createdAt: (json['createdAt'] as num).toInt(),
  expiresAt: (json['expiresAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$ShareRecordToJson(_ShareRecord instance) =>
    <String, dynamic>{
      'code': instance.code,
      'path': instance.path,
      'fileName': instance.fileName,
      'size': instance.size,
      'passwordHash': instance.passwordHash,
      'createdAt': instance.createdAt,
      'expiresAt': instance.expiresAt,
    };

_ShareInfo _$ShareInfoFromJson(Map<String, dynamic> json) => _ShareInfo(
  code: json['code'] as String,
  path: json['path'] as String,
  fileName: json['fileName'] as String,
  size: (json['size'] as num).toInt(),
  hasPassword: json['hasPassword'] as bool,
  createdAt: (json['createdAt'] as num).toInt(),
  expiresAt: (json['expiresAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$ShareInfoToJson(_ShareInfo instance) =>
    <String, dynamic>{
      'code': instance.code,
      'path': instance.path,
      'fileName': instance.fileName,
      'size': instance.size,
      'hasPassword': instance.hasPassword,
      'createdAt': instance.createdAt,
      'expiresAt': instance.expiresAt,
    };
