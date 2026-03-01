// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fs_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FsEntry _$FsEntryFromJson(Map<String, dynamic> json) => _FsEntry(
  path: json['path'] as String,
  name: json['name'] as String,
  size: (json['size'] as num).toInt(),
  mtime: (json['mtime'] as num).toInt(),
  isDirectory: json['isDirectory'] as bool,
);

Map<String, dynamic> _$FsEntryToJson(_FsEntry instance) => <String, dynamic>{
  'path': instance.path,
  'name': instance.name,
  'size': instance.size,
  'mtime': instance.mtime,
  'isDirectory': instance.isDirectory,
};
