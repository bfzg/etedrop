// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Contact {

 String get userId; String get displayName; int get avatar; ContactTransport get transport; String? get ip; int? get port; String? get os; bool get isOnline; bool get autoDiscovered; int get addedAt; int get lastSeenAt;
/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactCopyWith<Contact> get copyWith => _$ContactCopyWithImpl<Contact>(this as Contact, _$identity);

  /// Serializes this Contact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contact&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.port, port) || other.port == port)&&(identical(other.os, os) || other.os == os)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.autoDiscovered, autoDiscovered) || other.autoDiscovered == autoDiscovered)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,avatar,transport,ip,port,os,isOnline,autoDiscovered,addedAt,lastSeenAt);

@override
String toString() {
  return 'Contact(userId: $userId, displayName: $displayName, avatar: $avatar, transport: $transport, ip: $ip, port: $port, os: $os, isOnline: $isOnline, autoDiscovered: $autoDiscovered, addedAt: $addedAt, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class $ContactCopyWith<$Res>  {
  factory $ContactCopyWith(Contact value, $Res Function(Contact) _then) = _$ContactCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, int avatar, ContactTransport transport, String? ip, int? port, String? os, bool isOnline, bool autoDiscovered, int addedAt, int lastSeenAt
});




}
/// @nodoc
class _$ContactCopyWithImpl<$Res>
    implements $ContactCopyWith<$Res> {
  _$ContactCopyWithImpl(this._self, this._then);

  final Contact _self;
  final $Res Function(Contact) _then;

/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? avatar = null,Object? transport = null,Object? ip = freezed,Object? port = freezed,Object? os = freezed,Object? isOnline = null,Object? autoDiscovered = null,Object? addedAt = null,Object? lastSeenAt = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as int,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as ContactTransport,ip: freezed == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String?,port: freezed == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int?,os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,autoDiscovered: null == autoDiscovered ? _self.autoDiscovered : autoDiscovered // ignore: cast_nullable_to_non_nullable
as bool,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as int,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Contact].
extension ContactPatterns on Contact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Contact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Contact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Contact value)  $default,){
final _that = this;
switch (_that) {
case _Contact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Contact value)?  $default,){
final _that = this;
switch (_that) {
case _Contact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  int avatar,  ContactTransport transport,  String? ip,  int? port,  String? os,  bool isOnline,  bool autoDiscovered,  int addedAt,  int lastSeenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Contact() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatar,_that.transport,_that.ip,_that.port,_that.os,_that.isOnline,_that.autoDiscovered,_that.addedAt,_that.lastSeenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  int avatar,  ContactTransport transport,  String? ip,  int? port,  String? os,  bool isOnline,  bool autoDiscovered,  int addedAt,  int lastSeenAt)  $default,) {final _that = this;
switch (_that) {
case _Contact():
return $default(_that.userId,_that.displayName,_that.avatar,_that.transport,_that.ip,_that.port,_that.os,_that.isOnline,_that.autoDiscovered,_that.addedAt,_that.lastSeenAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  int avatar,  ContactTransport transport,  String? ip,  int? port,  String? os,  bool isOnline,  bool autoDiscovered,  int addedAt,  int lastSeenAt)?  $default,) {final _that = this;
switch (_that) {
case _Contact() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatar,_that.transport,_that.ip,_that.port,_that.os,_that.isOnline,_that.autoDiscovered,_that.addedAt,_that.lastSeenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Contact implements Contact {
  const _Contact({required this.userId, required this.displayName, this.avatar = 1, this.transport = ContactTransport.lan, this.ip, this.port, this.os, this.isOnline = false, this.autoDiscovered = true, required this.addedAt, this.lastSeenAt = 0});
  factory _Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);

@override final  String userId;
@override final  String displayName;
@override@JsonKey() final  int avatar;
@override@JsonKey() final  ContactTransport transport;
@override final  String? ip;
@override final  int? port;
@override final  String? os;
@override@JsonKey() final  bool isOnline;
@override@JsonKey() final  bool autoDiscovered;
@override final  int addedAt;
@override@JsonKey() final  int lastSeenAt;

/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContactCopyWith<_Contact> get copyWith => __$ContactCopyWithImpl<_Contact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContactToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Contact&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.port, port) || other.port == port)&&(identical(other.os, os) || other.os == os)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.autoDiscovered, autoDiscovered) || other.autoDiscovered == autoDiscovered)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,avatar,transport,ip,port,os,isOnline,autoDiscovered,addedAt,lastSeenAt);

@override
String toString() {
  return 'Contact(userId: $userId, displayName: $displayName, avatar: $avatar, transport: $transport, ip: $ip, port: $port, os: $os, isOnline: $isOnline, autoDiscovered: $autoDiscovered, addedAt: $addedAt, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class _$ContactCopyWith<$Res> implements $ContactCopyWith<$Res> {
  factory _$ContactCopyWith(_Contact value, $Res Function(_Contact) _then) = __$ContactCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, int avatar, ContactTransport transport, String? ip, int? port, String? os, bool isOnline, bool autoDiscovered, int addedAt, int lastSeenAt
});




}
/// @nodoc
class __$ContactCopyWithImpl<$Res>
    implements _$ContactCopyWith<$Res> {
  __$ContactCopyWithImpl(this._self, this._then);

  final _Contact _self;
  final $Res Function(_Contact) _then;

/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? avatar = null,Object? transport = null,Object? ip = freezed,Object? port = freezed,Object? os = freezed,Object? isOnline = null,Object? autoDiscovered = null,Object? addedAt = null,Object? lastSeenAt = null,}) {
  return _then(_Contact(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as int,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as ContactTransport,ip: freezed == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String?,port: freezed == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int?,os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,autoDiscovered: null == autoDiscovered ? _self.autoDiscovered : autoDiscovered // ignore: cast_nullable_to_non_nullable
as bool,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as int,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
