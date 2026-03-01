// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fs_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FsEntry {

/// 相对于存储根目录的路径
 String get path;/// 文件/文件夹名称
 String get name;/// 文件大小（字节），文件夹为 0
 int get size;/// 最后修改时间（毫秒时间戳）
 int get mtime;/// 是否为文件夹
 bool get isDirectory;
/// Create a copy of FsEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FsEntryCopyWith<FsEntry> get copyWith => _$FsEntryCopyWithImpl<FsEntry>(this as FsEntry, _$identity);

  /// Serializes this FsEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FsEntry&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.mtime, mtime) || other.mtime == mtime)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,name,size,mtime,isDirectory);

@override
String toString() {
  return 'FsEntry(path: $path, name: $name, size: $size, mtime: $mtime, isDirectory: $isDirectory)';
}


}

/// @nodoc
abstract mixin class $FsEntryCopyWith<$Res>  {
  factory $FsEntryCopyWith(FsEntry value, $Res Function(FsEntry) _then) = _$FsEntryCopyWithImpl;
@useResult
$Res call({
 String path, String name, int size, int mtime, bool isDirectory
});




}
/// @nodoc
class _$FsEntryCopyWithImpl<$Res>
    implements $FsEntryCopyWith<$Res> {
  _$FsEntryCopyWithImpl(this._self, this._then);

  final FsEntry _self;
  final $Res Function(FsEntry) _then;

/// Create a copy of FsEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,Object? size = null,Object? mtime = null,Object? isDirectory = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mtime: null == mtime ? _self.mtime : mtime // ignore: cast_nullable_to_non_nullable
as int,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FsEntry].
extension FsEntryPatterns on FsEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FsEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FsEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FsEntry value)  $default,){
final _that = this;
switch (_that) {
case _FsEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FsEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FsEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String name,  int size,  int mtime,  bool isDirectory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FsEntry() when $default != null:
return $default(_that.path,_that.name,_that.size,_that.mtime,_that.isDirectory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String name,  int size,  int mtime,  bool isDirectory)  $default,) {final _that = this;
switch (_that) {
case _FsEntry():
return $default(_that.path,_that.name,_that.size,_that.mtime,_that.isDirectory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String name,  int size,  int mtime,  bool isDirectory)?  $default,) {final _that = this;
switch (_that) {
case _FsEntry() when $default != null:
return $default(_that.path,_that.name,_that.size,_that.mtime,_that.isDirectory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FsEntry implements FsEntry {
  const _FsEntry({required this.path, required this.name, required this.size, required this.mtime, required this.isDirectory});
  factory _FsEntry.fromJson(Map<String, dynamic> json) => _$FsEntryFromJson(json);

/// 相对于存储根目录的路径
@override final  String path;
/// 文件/文件夹名称
@override final  String name;
/// 文件大小（字节），文件夹为 0
@override final  int size;
/// 最后修改时间（毫秒时间戳）
@override final  int mtime;
/// 是否为文件夹
@override final  bool isDirectory;

/// Create a copy of FsEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FsEntryCopyWith<_FsEntry> get copyWith => __$FsEntryCopyWithImpl<_FsEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FsEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FsEntry&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.mtime, mtime) || other.mtime == mtime)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,name,size,mtime,isDirectory);

@override
String toString() {
  return 'FsEntry(path: $path, name: $name, size: $size, mtime: $mtime, isDirectory: $isDirectory)';
}


}

/// @nodoc
abstract mixin class _$FsEntryCopyWith<$Res> implements $FsEntryCopyWith<$Res> {
  factory _$FsEntryCopyWith(_FsEntry value, $Res Function(_FsEntry) _then) = __$FsEntryCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, int size, int mtime, bool isDirectory
});




}
/// @nodoc
class __$FsEntryCopyWithImpl<$Res>
    implements _$FsEntryCopyWith<$Res> {
  __$FsEntryCopyWithImpl(this._self, this._then);

  final _FsEntry _self;
  final $Res Function(_FsEntry) _then;

/// Create a copy of FsEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? size = null,Object? mtime = null,Object? isDirectory = null,}) {
  return _then(_FsEntry(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mtime: null == mtime ? _self.mtime : mtime // ignore: cast_nullable_to_non_nullable
as int,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
