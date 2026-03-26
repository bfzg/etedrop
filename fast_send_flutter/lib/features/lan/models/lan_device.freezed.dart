// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lan_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LanDevice {

 String get deviceId; String get deviceName; String get ip; int get port; String get os; int get lastSeen; int get avatar;
/// Create a copy of LanDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanDeviceCopyWith<LanDevice> get copyWith => _$LanDeviceCopyWithImpl<LanDevice>(this as LanDevice, _$identity);

  /// Serializes this LanDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LanDevice&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.port, port) || other.port == port)&&(identical(other.os, os) || other.os == os)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,ip,port,os,lastSeen,avatar);

@override
String toString() {
  return 'LanDevice(deviceId: $deviceId, deviceName: $deviceName, ip: $ip, port: $port, os: $os, lastSeen: $lastSeen, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class $LanDeviceCopyWith<$Res>  {
  factory $LanDeviceCopyWith(LanDevice value, $Res Function(LanDevice) _then) = _$LanDeviceCopyWithImpl;
@useResult
$Res call({
 String deviceId, String deviceName, String ip, int port, String os, int lastSeen, int avatar
});




}
/// @nodoc
class _$LanDeviceCopyWithImpl<$Res>
    implements $LanDeviceCopyWith<$Res> {
  _$LanDeviceCopyWithImpl(this._self, this._then);

  final LanDevice _self;
  final $Res Function(LanDevice) _then;

/// Create a copy of LanDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? deviceName = null,Object? ip = null,Object? port = null,Object? os = null,Object? lastSeen = null,Object? avatar = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,ip: null == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,os: null == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as int,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LanDevice].
extension LanDevicePatterns on LanDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LanDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LanDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LanDevice value)  $default,){
final _that = this;
switch (_that) {
case _LanDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LanDevice value)?  $default,){
final _that = this;
switch (_that) {
case _LanDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceId,  String deviceName,  String ip,  int port,  String os,  int lastSeen,  int avatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LanDevice() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.ip,_that.port,_that.os,_that.lastSeen,_that.avatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceId,  String deviceName,  String ip,  int port,  String os,  int lastSeen,  int avatar)  $default,) {final _that = this;
switch (_that) {
case _LanDevice():
return $default(_that.deviceId,_that.deviceName,_that.ip,_that.port,_that.os,_that.lastSeen,_that.avatar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceId,  String deviceName,  String ip,  int port,  String os,  int lastSeen,  int avatar)?  $default,) {final _that = this;
switch (_that) {
case _LanDevice() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.ip,_that.port,_that.os,_that.lastSeen,_that.avatar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LanDevice implements LanDevice {
  const _LanDevice({required this.deviceId, required this.deviceName, required this.ip, required this.port, required this.os, this.lastSeen = 0, this.avatar = 1});
  factory _LanDevice.fromJson(Map<String, dynamic> json) => _$LanDeviceFromJson(json);

@override final  String deviceId;
@override final  String deviceName;
@override final  String ip;
@override final  int port;
@override final  String os;
@override@JsonKey() final  int lastSeen;
@override@JsonKey() final  int avatar;

/// Create a copy of LanDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LanDeviceCopyWith<_LanDevice> get copyWith => __$LanDeviceCopyWithImpl<_LanDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LanDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LanDevice&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.port, port) || other.port == port)&&(identical(other.os, os) || other.os == os)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,ip,port,os,lastSeen,avatar);

@override
String toString() {
  return 'LanDevice(deviceId: $deviceId, deviceName: $deviceName, ip: $ip, port: $port, os: $os, lastSeen: $lastSeen, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class _$LanDeviceCopyWith<$Res> implements $LanDeviceCopyWith<$Res> {
  factory _$LanDeviceCopyWith(_LanDevice value, $Res Function(_LanDevice) _then) = __$LanDeviceCopyWithImpl;
@override @useResult
$Res call({
 String deviceId, String deviceName, String ip, int port, String os, int lastSeen, int avatar
});




}
/// @nodoc
class __$LanDeviceCopyWithImpl<$Res>
    implements _$LanDeviceCopyWith<$Res> {
  __$LanDeviceCopyWithImpl(this._self, this._then);

  final _LanDevice _self;
  final $Res Function(_LanDevice) _then;

/// Create a copy of LanDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? deviceName = null,Object? ip = null,Object? port = null,Object? os = null,Object? lastSeen = null,Object? avatar = null,}) {
  return _then(_LanDevice(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,ip: null == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,os: null == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as int,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
