// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransferMessage {

 String get id; String get fileName; int get fileSize; String get senderName; String get senderDeviceId; int get timestamp; TransferMessageStatus get status; double get progress; String? get errorMessage;
/// Create a copy of TransferMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferMessageCopyWith<TransferMessage> get copyWith => _$TransferMessageCopyWithImpl<TransferMessage>(this as TransferMessage, _$identity);

  /// Serializes this TransferMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderDeviceId, senderDeviceId) || other.senderDeviceId == senderDeviceId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,fileSize,senderName,senderDeviceId,timestamp,status,progress,errorMessage);

@override
String toString() {
  return 'TransferMessage(id: $id, fileName: $fileName, fileSize: $fileSize, senderName: $senderName, senderDeviceId: $senderDeviceId, timestamp: $timestamp, status: $status, progress: $progress, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $TransferMessageCopyWith<$Res>  {
  factory $TransferMessageCopyWith(TransferMessage value, $Res Function(TransferMessage) _then) = _$TransferMessageCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, int fileSize, String senderName, String senderDeviceId, int timestamp, TransferMessageStatus status, double progress, String? errorMessage
});




}
/// @nodoc
class _$TransferMessageCopyWithImpl<$Res>
    implements $TransferMessageCopyWith<$Res> {
  _$TransferMessageCopyWithImpl(this._self, this._then);

  final TransferMessage _self;
  final $Res Function(TransferMessage) _then;

/// Create a copy of TransferMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? fileSize = null,Object? senderName = null,Object? senderDeviceId = null,Object? timestamp = null,Object? status = null,Object? progress = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderDeviceId: null == senderDeviceId ? _self.senderDeviceId : senderDeviceId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferMessageStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransferMessage].
extension TransferMessagePatterns on TransferMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransferMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransferMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransferMessage value)  $default,){
final _that = this;
switch (_that) {
case _TransferMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransferMessage value)?  $default,){
final _that = this;
switch (_that) {
case _TransferMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  int fileSize,  String senderName,  String senderDeviceId,  int timestamp,  TransferMessageStatus status,  double progress,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferMessage() when $default != null:
return $default(_that.id,_that.fileName,_that.fileSize,_that.senderName,_that.senderDeviceId,_that.timestamp,_that.status,_that.progress,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  int fileSize,  String senderName,  String senderDeviceId,  int timestamp,  TransferMessageStatus status,  double progress,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _TransferMessage():
return $default(_that.id,_that.fileName,_that.fileSize,_that.senderName,_that.senderDeviceId,_that.timestamp,_that.status,_that.progress,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  int fileSize,  String senderName,  String senderDeviceId,  int timestamp,  TransferMessageStatus status,  double progress,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _TransferMessage() when $default != null:
return $default(_that.id,_that.fileName,_that.fileSize,_that.senderName,_that.senderDeviceId,_that.timestamp,_that.status,_that.progress,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransferMessage implements TransferMessage {
  const _TransferMessage({required this.id, required this.fileName, required this.fileSize, required this.senderName, required this.senderDeviceId, required this.timestamp, this.status = TransferMessageStatus.pending, this.progress = 0.0, this.errorMessage});
  factory _TransferMessage.fromJson(Map<String, dynamic> json) => _$TransferMessageFromJson(json);

@override final  String id;
@override final  String fileName;
@override final  int fileSize;
@override final  String senderName;
@override final  String senderDeviceId;
@override final  int timestamp;
@override@JsonKey() final  TransferMessageStatus status;
@override@JsonKey() final  double progress;
@override final  String? errorMessage;

/// Create a copy of TransferMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferMessageCopyWith<_TransferMessage> get copyWith => __$TransferMessageCopyWithImpl<_TransferMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransferMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderDeviceId, senderDeviceId) || other.senderDeviceId == senderDeviceId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,fileSize,senderName,senderDeviceId,timestamp,status,progress,errorMessage);

@override
String toString() {
  return 'TransferMessage(id: $id, fileName: $fileName, fileSize: $fileSize, senderName: $senderName, senderDeviceId: $senderDeviceId, timestamp: $timestamp, status: $status, progress: $progress, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$TransferMessageCopyWith<$Res> implements $TransferMessageCopyWith<$Res> {
  factory _$TransferMessageCopyWith(_TransferMessage value, $Res Function(_TransferMessage) _then) = __$TransferMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, int fileSize, String senderName, String senderDeviceId, int timestamp, TransferMessageStatus status, double progress, String? errorMessage
});




}
/// @nodoc
class __$TransferMessageCopyWithImpl<$Res>
    implements _$TransferMessageCopyWith<$Res> {
  __$TransferMessageCopyWithImpl(this._self, this._then);

  final _TransferMessage _self;
  final $Res Function(_TransferMessage) _then;

/// Create a copy of TransferMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? fileSize = null,Object? senderName = null,Object? senderDeviceId = null,Object? timestamp = null,Object? status = null,Object? progress = null,Object? errorMessage = freezed,}) {
  return _then(_TransferMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderDeviceId: null == senderDeviceId ? _self.senderDeviceId : senderDeviceId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferMessageStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
