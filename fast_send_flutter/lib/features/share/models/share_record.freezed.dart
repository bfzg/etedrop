// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'share_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShareRecord {

/// 分享码（8位十六进制）
 String get code;/// 文件相对路径
 String get path;/// 文件名
 String get fileName;/// 文件大小（字节）
 int get size;/// SHA256 哈希后的密码，null 表示无密码
 String? get passwordHash;/// 创建时间戳（毫秒）
 int get createdAt;/// 过期时间戳（毫秒），null 表示永不过期
 int? get expiresAt;
/// Create a copy of ShareRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShareRecordCopyWith<ShareRecord> get copyWith => _$ShareRecordCopyWithImpl<ShareRecord>(this as ShareRecord, _$identity);

  /// Serializes this ShareRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShareRecord&&(identical(other.code, code) || other.code == code)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.size, size) || other.size == size)&&(identical(other.passwordHash, passwordHash) || other.passwordHash == passwordHash)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,path,fileName,size,passwordHash,createdAt,expiresAt);

@override
String toString() {
  return 'ShareRecord(code: $code, path: $path, fileName: $fileName, size: $size, passwordHash: $passwordHash, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ShareRecordCopyWith<$Res>  {
  factory $ShareRecordCopyWith(ShareRecord value, $Res Function(ShareRecord) _then) = _$ShareRecordCopyWithImpl;
@useResult
$Res call({
 String code, String path, String fileName, int size, String? passwordHash, int createdAt, int? expiresAt
});




}
/// @nodoc
class _$ShareRecordCopyWithImpl<$Res>
    implements $ShareRecordCopyWith<$Res> {
  _$ShareRecordCopyWithImpl(this._self, this._then);

  final ShareRecord _self;
  final $Res Function(ShareRecord) _then;

/// Create a copy of ShareRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? path = null,Object? fileName = null,Object? size = null,Object? passwordHash = freezed,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,passwordHash: freezed == passwordHash ? _self.passwordHash : passwordHash // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShareRecord].
extension ShareRecordPatterns on ShareRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShareRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShareRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShareRecord value)  $default,){
final _that = this;
switch (_that) {
case _ShareRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShareRecord value)?  $default,){
final _that = this;
switch (_that) {
case _ShareRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String path,  String fileName,  int size,  String? passwordHash,  int createdAt,  int? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShareRecord() when $default != null:
return $default(_that.code,_that.path,_that.fileName,_that.size,_that.passwordHash,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String path,  String fileName,  int size,  String? passwordHash,  int createdAt,  int? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ShareRecord():
return $default(_that.code,_that.path,_that.fileName,_that.size,_that.passwordHash,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String path,  String fileName,  int size,  String? passwordHash,  int createdAt,  int? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ShareRecord() when $default != null:
return $default(_that.code,_that.path,_that.fileName,_that.size,_that.passwordHash,_that.createdAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShareRecord implements ShareRecord {
  const _ShareRecord({required this.code, required this.path, required this.fileName, required this.size, this.passwordHash, required this.createdAt, this.expiresAt});
  factory _ShareRecord.fromJson(Map<String, dynamic> json) => _$ShareRecordFromJson(json);

/// 分享码（8位十六进制）
@override final  String code;
/// 文件相对路径
@override final  String path;
/// 文件名
@override final  String fileName;
/// 文件大小（字节）
@override final  int size;
/// SHA256 哈希后的密码，null 表示无密码
@override final  String? passwordHash;
/// 创建时间戳（毫秒）
@override final  int createdAt;
/// 过期时间戳（毫秒），null 表示永不过期
@override final  int? expiresAt;

/// Create a copy of ShareRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShareRecordCopyWith<_ShareRecord> get copyWith => __$ShareRecordCopyWithImpl<_ShareRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShareRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShareRecord&&(identical(other.code, code) || other.code == code)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.size, size) || other.size == size)&&(identical(other.passwordHash, passwordHash) || other.passwordHash == passwordHash)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,path,fileName,size,passwordHash,createdAt,expiresAt);

@override
String toString() {
  return 'ShareRecord(code: $code, path: $path, fileName: $fileName, size: $size, passwordHash: $passwordHash, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ShareRecordCopyWith<$Res> implements $ShareRecordCopyWith<$Res> {
  factory _$ShareRecordCopyWith(_ShareRecord value, $Res Function(_ShareRecord) _then) = __$ShareRecordCopyWithImpl;
@override @useResult
$Res call({
 String code, String path, String fileName, int size, String? passwordHash, int createdAt, int? expiresAt
});




}
/// @nodoc
class __$ShareRecordCopyWithImpl<$Res>
    implements _$ShareRecordCopyWith<$Res> {
  __$ShareRecordCopyWithImpl(this._self, this._then);

  final _ShareRecord _self;
  final $Res Function(_ShareRecord) _then;

/// Create a copy of ShareRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? path = null,Object? fileName = null,Object? size = null,Object? passwordHash = freezed,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_ShareRecord(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,passwordHash: freezed == passwordHash ? _self.passwordHash : passwordHash // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ShareInfo {

 String get code; String get path; String get fileName; int get size; bool get hasPassword; int get createdAt; int? get expiresAt;
/// Create a copy of ShareInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShareInfoCopyWith<ShareInfo> get copyWith => _$ShareInfoCopyWithImpl<ShareInfo>(this as ShareInfo, _$identity);

  /// Serializes this ShareInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShareInfo&&(identical(other.code, code) || other.code == code)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.size, size) || other.size == size)&&(identical(other.hasPassword, hasPassword) || other.hasPassword == hasPassword)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,path,fileName,size,hasPassword,createdAt,expiresAt);

@override
String toString() {
  return 'ShareInfo(code: $code, path: $path, fileName: $fileName, size: $size, hasPassword: $hasPassword, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ShareInfoCopyWith<$Res>  {
  factory $ShareInfoCopyWith(ShareInfo value, $Res Function(ShareInfo) _then) = _$ShareInfoCopyWithImpl;
@useResult
$Res call({
 String code, String path, String fileName, int size, bool hasPassword, int createdAt, int? expiresAt
});




}
/// @nodoc
class _$ShareInfoCopyWithImpl<$Res>
    implements $ShareInfoCopyWith<$Res> {
  _$ShareInfoCopyWithImpl(this._self, this._then);

  final ShareInfo _self;
  final $Res Function(ShareInfo) _then;

/// Create a copy of ShareInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? path = null,Object? fileName = null,Object? size = null,Object? hasPassword = null,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShareInfo].
extension ShareInfoPatterns on ShareInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShareInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShareInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShareInfo value)  $default,){
final _that = this;
switch (_that) {
case _ShareInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShareInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ShareInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String path,  String fileName,  int size,  bool hasPassword,  int createdAt,  int? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShareInfo() when $default != null:
return $default(_that.code,_that.path,_that.fileName,_that.size,_that.hasPassword,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String path,  String fileName,  int size,  bool hasPassword,  int createdAt,  int? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ShareInfo():
return $default(_that.code,_that.path,_that.fileName,_that.size,_that.hasPassword,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String path,  String fileName,  int size,  bool hasPassword,  int createdAt,  int? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ShareInfo() when $default != null:
return $default(_that.code,_that.path,_that.fileName,_that.size,_that.hasPassword,_that.createdAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShareInfo implements ShareInfo {
  const _ShareInfo({required this.code, required this.path, required this.fileName, required this.size, required this.hasPassword, required this.createdAt, this.expiresAt});
  factory _ShareInfo.fromJson(Map<String, dynamic> json) => _$ShareInfoFromJson(json);

@override final  String code;
@override final  String path;
@override final  String fileName;
@override final  int size;
@override final  bool hasPassword;
@override final  int createdAt;
@override final  int? expiresAt;

/// Create a copy of ShareInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShareInfoCopyWith<_ShareInfo> get copyWith => __$ShareInfoCopyWithImpl<_ShareInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShareInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShareInfo&&(identical(other.code, code) || other.code == code)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.size, size) || other.size == size)&&(identical(other.hasPassword, hasPassword) || other.hasPassword == hasPassword)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,path,fileName,size,hasPassword,createdAt,expiresAt);

@override
String toString() {
  return 'ShareInfo(code: $code, path: $path, fileName: $fileName, size: $size, hasPassword: $hasPassword, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ShareInfoCopyWith<$Res> implements $ShareInfoCopyWith<$Res> {
  factory _$ShareInfoCopyWith(_ShareInfo value, $Res Function(_ShareInfo) _then) = __$ShareInfoCopyWithImpl;
@override @useResult
$Res call({
 String code, String path, String fileName, int size, bool hasPassword, int createdAt, int? expiresAt
});




}
/// @nodoc
class __$ShareInfoCopyWithImpl<$Res>
    implements _$ShareInfoCopyWith<$Res> {
  __$ShareInfoCopyWithImpl(this._self, this._then);

  final _ShareInfo _self;
  final $Res Function(_ShareInfo) _then;

/// Create a copy of ShareInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? path = null,Object? fileName = null,Object? size = null,Object? hasPassword = null,Object? createdAt = null,Object? expiresAt = freezed,}) {
  return _then(_ShareInfo(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
