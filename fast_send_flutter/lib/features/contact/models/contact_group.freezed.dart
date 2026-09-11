// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contact_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContactGroup {

 String get groupId; String get name; String get ownerId; int get avatar; List<String> get memberIds; int get createdAt; int get updatedAt;
/// Create a copy of ContactGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactGroupCopyWith<ContactGroup> get copyWith => _$ContactGroupCopyWithImpl<ContactGroup>(this as ContactGroup, _$identity);

  /// Serializes this ContactGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactGroup&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&const DeepCollectionEquality().equals(other.memberIds, memberIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupId,name,ownerId,avatar,const DeepCollectionEquality().hash(memberIds),createdAt,updatedAt);

@override
String toString() {
  return 'ContactGroup(groupId: $groupId, name: $name, ownerId: $ownerId, avatar: $avatar, memberIds: $memberIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ContactGroupCopyWith<$Res>  {
  factory $ContactGroupCopyWith(ContactGroup value, $Res Function(ContactGroup) _then) = _$ContactGroupCopyWithImpl;
@useResult
$Res call({
 String groupId, String name, String ownerId, int avatar, List<String> memberIds, int createdAt, int updatedAt
});




}
/// @nodoc
class _$ContactGroupCopyWithImpl<$Res>
    implements $ContactGroupCopyWith<$Res> {
  _$ContactGroupCopyWithImpl(this._self, this._then);

  final ContactGroup _self;
  final $Res Function(ContactGroup) _then;

/// Create a copy of ContactGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? name = null,Object? ownerId = null,Object? avatar = null,Object? memberIds = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as int,memberIds: null == memberIds ? _self.memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ContactGroup].
extension ContactGroupPatterns on ContactGroup {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContactGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContactGroup() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContactGroup value)  $default,){
final _that = this;
switch (_that) {
case _ContactGroup():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContactGroup value)?  $default,){
final _that = this;
switch (_that) {
case _ContactGroup() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  String name,  String ownerId,  int avatar,  List<String> memberIds,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContactGroup() when $default != null:
return $default(_that.groupId,_that.name,_that.ownerId,_that.avatar,_that.memberIds,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  String name,  String ownerId,  int avatar,  List<String> memberIds,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ContactGroup():
return $default(_that.groupId,_that.name,_that.ownerId,_that.avatar,_that.memberIds,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  String name,  String ownerId,  int avatar,  List<String> memberIds,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ContactGroup() when $default != null:
return $default(_that.groupId,_that.name,_that.ownerId,_that.avatar,_that.memberIds,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContactGroup implements ContactGroup {
  const _ContactGroup({required this.groupId, required this.name, required this.ownerId, this.avatar = 1, final  List<String> memberIds = const <String>[], required this.createdAt, required this.updatedAt}): _memberIds = memberIds;
  factory _ContactGroup.fromJson(Map<String, dynamic> json) => _$ContactGroupFromJson(json);

@override final  String groupId;
@override final  String name;
@override final  String ownerId;
@override@JsonKey() final  int avatar;
 final  List<String> _memberIds;
@override@JsonKey() List<String> get memberIds {
  if (_memberIds is EqualUnmodifiableListView) return _memberIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberIds);
}

@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of ContactGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContactGroupCopyWith<_ContactGroup> get copyWith => __$ContactGroupCopyWithImpl<_ContactGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContactGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContactGroup&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&const DeepCollectionEquality().equals(other._memberIds, _memberIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupId,name,ownerId,avatar,const DeepCollectionEquality().hash(_memberIds),createdAt,updatedAt);

@override
String toString() {
  return 'ContactGroup(groupId: $groupId, name: $name, ownerId: $ownerId, avatar: $avatar, memberIds: $memberIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ContactGroupCopyWith<$Res> implements $ContactGroupCopyWith<$Res> {
  factory _$ContactGroupCopyWith(_ContactGroup value, $Res Function(_ContactGroup) _then) = __$ContactGroupCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String name, String ownerId, int avatar, List<String> memberIds, int createdAt, int updatedAt
});




}
/// @nodoc
class __$ContactGroupCopyWithImpl<$Res>
    implements _$ContactGroupCopyWith<$Res> {
  __$ContactGroupCopyWithImpl(this._self, this._then);

  final _ContactGroup _self;
  final $Res Function(_ContactGroup) _then;

/// Create a copy of ContactGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? name = null,Object? ownerId = null,Object? avatar = null,Object? memberIds = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ContactGroup(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as int,memberIds: null == memberIds ? _self._memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
