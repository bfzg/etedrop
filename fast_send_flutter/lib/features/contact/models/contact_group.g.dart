// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContactGroup _$ContactGroupFromJson(Map<String, dynamic> json) =>
    _ContactGroup(
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      avatar: (json['avatar'] as num?)?.toInt() ?? 1,
      memberIds:
          (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$ContactGroupToJson(_ContactGroup instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'name': instance.name,
      'ownerId': instance.ownerId,
      'avatar': instance.avatar,
      'memberIds': instance.memberIds,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
