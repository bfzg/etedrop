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

 String get id; String get fileName; int get fileSize; String get senderName; String get senderDeviceId; int get senderAvatar; int get timestamp; TransferMessageStatus get status; double get progress; String? get errorMessage;/// 局域网批量分享 ID（与发送方会话一致）
 String? get shareId; bool get isBatch;/// JSON 数组：[{"name":"a","size":1},...]
 String? get batchFilesJson;/// 发送方 HTTP 地址（接收方接受/拒绝时回调）
 String? get senderHttpHost; int? get senderHttpPort;/// 本机发出的批量分享（消息列表中展示「发送」侧）
 bool get isOutgoing;/// JSON 数组：本机绝对路径，用于发送方过期后重试
 String? get localFilePathsJson;/// JSON 数组：目标 deviceId，用于重试
 String? get targetDeviceIdsJson;
/// Create a copy of TransferMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferMessageCopyWith<TransferMessage> get copyWith => _$TransferMessageCopyWithImpl<TransferMessage>(this as TransferMessage, _$identity);

  /// Serializes this TransferMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderDeviceId, senderDeviceId) || other.senderDeviceId == senderDeviceId)&&(identical(other.senderAvatar, senderAvatar) || other.senderAvatar == senderAvatar)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.shareId, shareId) || other.shareId == shareId)&&(identical(other.isBatch, isBatch) || other.isBatch == isBatch)&&(identical(other.batchFilesJson, batchFilesJson) || other.batchFilesJson == batchFilesJson)&&(identical(other.senderHttpHost, senderHttpHost) || other.senderHttpHost == senderHttpHost)&&(identical(other.senderHttpPort, senderHttpPort) || other.senderHttpPort == senderHttpPort)&&(identical(other.isOutgoing, isOutgoing) || other.isOutgoing == isOutgoing)&&(identical(other.localFilePathsJson, localFilePathsJson) || other.localFilePathsJson == localFilePathsJson)&&(identical(other.targetDeviceIdsJson, targetDeviceIdsJson) || other.targetDeviceIdsJson == targetDeviceIdsJson));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,fileSize,senderName,senderDeviceId,senderAvatar,timestamp,status,progress,errorMessage,shareId,isBatch,batchFilesJson,senderHttpHost,senderHttpPort,isOutgoing,localFilePathsJson,targetDeviceIdsJson);

@override
String toString() {
  return 'TransferMessage(id: $id, fileName: $fileName, fileSize: $fileSize, senderName: $senderName, senderDeviceId: $senderDeviceId, senderAvatar: $senderAvatar, timestamp: $timestamp, status: $status, progress: $progress, errorMessage: $errorMessage, shareId: $shareId, isBatch: $isBatch, batchFilesJson: $batchFilesJson, senderHttpHost: $senderHttpHost, senderHttpPort: $senderHttpPort, isOutgoing: $isOutgoing, localFilePathsJson: $localFilePathsJson, targetDeviceIdsJson: $targetDeviceIdsJson)';
}


}

/// @nodoc
abstract mixin class $TransferMessageCopyWith<$Res>  {
  factory $TransferMessageCopyWith(TransferMessage value, $Res Function(TransferMessage) _then) = _$TransferMessageCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, int fileSize, String senderName, String senderDeviceId, int senderAvatar, int timestamp, TransferMessageStatus status, double progress, String? errorMessage, String? shareId, bool isBatch, String? batchFilesJson, String? senderHttpHost, int? senderHttpPort, bool isOutgoing, String? localFilePathsJson, String? targetDeviceIdsJson
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? fileSize = null,Object? senderName = null,Object? senderDeviceId = null,Object? senderAvatar = null,Object? timestamp = null,Object? status = null,Object? progress = null,Object? errorMessage = freezed,Object? shareId = freezed,Object? isBatch = null,Object? batchFilesJson = freezed,Object? senderHttpHost = freezed,Object? senderHttpPort = freezed,Object? isOutgoing = null,Object? localFilePathsJson = freezed,Object? targetDeviceIdsJson = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderDeviceId: null == senderDeviceId ? _self.senderDeviceId : senderDeviceId // ignore: cast_nullable_to_non_nullable
as String,senderAvatar: null == senderAvatar ? _self.senderAvatar : senderAvatar // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferMessageStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,shareId: freezed == shareId ? _self.shareId : shareId // ignore: cast_nullable_to_non_nullable
as String?,isBatch: null == isBatch ? _self.isBatch : isBatch // ignore: cast_nullable_to_non_nullable
as bool,batchFilesJson: freezed == batchFilesJson ? _self.batchFilesJson : batchFilesJson // ignore: cast_nullable_to_non_nullable
as String?,senderHttpHost: freezed == senderHttpHost ? _self.senderHttpHost : senderHttpHost // ignore: cast_nullable_to_non_nullable
as String?,senderHttpPort: freezed == senderHttpPort ? _self.senderHttpPort : senderHttpPort // ignore: cast_nullable_to_non_nullable
as int?,isOutgoing: null == isOutgoing ? _self.isOutgoing : isOutgoing // ignore: cast_nullable_to_non_nullable
as bool,localFilePathsJson: freezed == localFilePathsJson ? _self.localFilePathsJson : localFilePathsJson // ignore: cast_nullable_to_non_nullable
as String?,targetDeviceIdsJson: freezed == targetDeviceIdsJson ? _self.targetDeviceIdsJson : targetDeviceIdsJson // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  int fileSize,  String senderName,  String senderDeviceId,  int senderAvatar,  int timestamp,  TransferMessageStatus status,  double progress,  String? errorMessage,  String? shareId,  bool isBatch,  String? batchFilesJson,  String? senderHttpHost,  int? senderHttpPort,  bool isOutgoing,  String? localFilePathsJson,  String? targetDeviceIdsJson)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferMessage() when $default != null:
return $default(_that.id,_that.fileName,_that.fileSize,_that.senderName,_that.senderDeviceId,_that.senderAvatar,_that.timestamp,_that.status,_that.progress,_that.errorMessage,_that.shareId,_that.isBatch,_that.batchFilesJson,_that.senderHttpHost,_that.senderHttpPort,_that.isOutgoing,_that.localFilePathsJson,_that.targetDeviceIdsJson);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  int fileSize,  String senderName,  String senderDeviceId,  int senderAvatar,  int timestamp,  TransferMessageStatus status,  double progress,  String? errorMessage,  String? shareId,  bool isBatch,  String? batchFilesJson,  String? senderHttpHost,  int? senderHttpPort,  bool isOutgoing,  String? localFilePathsJson,  String? targetDeviceIdsJson)  $default,) {final _that = this;
switch (_that) {
case _TransferMessage():
return $default(_that.id,_that.fileName,_that.fileSize,_that.senderName,_that.senderDeviceId,_that.senderAvatar,_that.timestamp,_that.status,_that.progress,_that.errorMessage,_that.shareId,_that.isBatch,_that.batchFilesJson,_that.senderHttpHost,_that.senderHttpPort,_that.isOutgoing,_that.localFilePathsJson,_that.targetDeviceIdsJson);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  int fileSize,  String senderName,  String senderDeviceId,  int senderAvatar,  int timestamp,  TransferMessageStatus status,  double progress,  String? errorMessage,  String? shareId,  bool isBatch,  String? batchFilesJson,  String? senderHttpHost,  int? senderHttpPort,  bool isOutgoing,  String? localFilePathsJson,  String? targetDeviceIdsJson)?  $default,) {final _that = this;
switch (_that) {
case _TransferMessage() when $default != null:
return $default(_that.id,_that.fileName,_that.fileSize,_that.senderName,_that.senderDeviceId,_that.senderAvatar,_that.timestamp,_that.status,_that.progress,_that.errorMessage,_that.shareId,_that.isBatch,_that.batchFilesJson,_that.senderHttpHost,_that.senderHttpPort,_that.isOutgoing,_that.localFilePathsJson,_that.targetDeviceIdsJson);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransferMessage implements TransferMessage {
  const _TransferMessage({required this.id, required this.fileName, required this.fileSize, required this.senderName, required this.senderDeviceId, this.senderAvatar = 1, required this.timestamp, this.status = TransferMessageStatus.pending, this.progress = 0.0, this.errorMessage, this.shareId, this.isBatch = false, this.batchFilesJson, this.senderHttpHost, this.senderHttpPort, this.isOutgoing = false, this.localFilePathsJson, this.targetDeviceIdsJson});
  factory _TransferMessage.fromJson(Map<String, dynamic> json) => _$TransferMessageFromJson(json);

@override final  String id;
@override final  String fileName;
@override final  int fileSize;
@override final  String senderName;
@override final  String senderDeviceId;
@override@JsonKey() final  int senderAvatar;
@override final  int timestamp;
@override@JsonKey() final  TransferMessageStatus status;
@override@JsonKey() final  double progress;
@override final  String? errorMessage;
/// 局域网批量分享 ID（与发送方会话一致）
@override final  String? shareId;
@override@JsonKey() final  bool isBatch;
/// JSON 数组：[{"name":"a","size":1},...]
@override final  String? batchFilesJson;
/// 发送方 HTTP 地址（接收方接受/拒绝时回调）
@override final  String? senderHttpHost;
@override final  int? senderHttpPort;
/// 本机发出的批量分享（消息列表中展示「发送」侧）
@override@JsonKey() final  bool isOutgoing;
/// JSON 数组：本机绝对路径，用于发送方过期后重试
@override final  String? localFilePathsJson;
/// JSON 数组：目标 deviceId，用于重试
@override final  String? targetDeviceIdsJson;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderDeviceId, senderDeviceId) || other.senderDeviceId == senderDeviceId)&&(identical(other.senderAvatar, senderAvatar) || other.senderAvatar == senderAvatar)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.shareId, shareId) || other.shareId == shareId)&&(identical(other.isBatch, isBatch) || other.isBatch == isBatch)&&(identical(other.batchFilesJson, batchFilesJson) || other.batchFilesJson == batchFilesJson)&&(identical(other.senderHttpHost, senderHttpHost) || other.senderHttpHost == senderHttpHost)&&(identical(other.senderHttpPort, senderHttpPort) || other.senderHttpPort == senderHttpPort)&&(identical(other.isOutgoing, isOutgoing) || other.isOutgoing == isOutgoing)&&(identical(other.localFilePathsJson, localFilePathsJson) || other.localFilePathsJson == localFilePathsJson)&&(identical(other.targetDeviceIdsJson, targetDeviceIdsJson) || other.targetDeviceIdsJson == targetDeviceIdsJson));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,fileSize,senderName,senderDeviceId,senderAvatar,timestamp,status,progress,errorMessage,shareId,isBatch,batchFilesJson,senderHttpHost,senderHttpPort,isOutgoing,localFilePathsJson,targetDeviceIdsJson);

@override
String toString() {
  return 'TransferMessage(id: $id, fileName: $fileName, fileSize: $fileSize, senderName: $senderName, senderDeviceId: $senderDeviceId, senderAvatar: $senderAvatar, timestamp: $timestamp, status: $status, progress: $progress, errorMessage: $errorMessage, shareId: $shareId, isBatch: $isBatch, batchFilesJson: $batchFilesJson, senderHttpHost: $senderHttpHost, senderHttpPort: $senderHttpPort, isOutgoing: $isOutgoing, localFilePathsJson: $localFilePathsJson, targetDeviceIdsJson: $targetDeviceIdsJson)';
}


}

/// @nodoc
abstract mixin class _$TransferMessageCopyWith<$Res> implements $TransferMessageCopyWith<$Res> {
  factory _$TransferMessageCopyWith(_TransferMessage value, $Res Function(_TransferMessage) _then) = __$TransferMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, int fileSize, String senderName, String senderDeviceId, int senderAvatar, int timestamp, TransferMessageStatus status, double progress, String? errorMessage, String? shareId, bool isBatch, String? batchFilesJson, String? senderHttpHost, int? senderHttpPort, bool isOutgoing, String? localFilePathsJson, String? targetDeviceIdsJson
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? fileSize = null,Object? senderName = null,Object? senderDeviceId = null,Object? senderAvatar = null,Object? timestamp = null,Object? status = null,Object? progress = null,Object? errorMessage = freezed,Object? shareId = freezed,Object? isBatch = null,Object? batchFilesJson = freezed,Object? senderHttpHost = freezed,Object? senderHttpPort = freezed,Object? isOutgoing = null,Object? localFilePathsJson = freezed,Object? targetDeviceIdsJson = freezed,}) {
  return _then(_TransferMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderDeviceId: null == senderDeviceId ? _self.senderDeviceId : senderDeviceId // ignore: cast_nullable_to_non_nullable
as String,senderAvatar: null == senderAvatar ? _self.senderAvatar : senderAvatar // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferMessageStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,shareId: freezed == shareId ? _self.shareId : shareId // ignore: cast_nullable_to_non_nullable
as String?,isBatch: null == isBatch ? _self.isBatch : isBatch // ignore: cast_nullable_to_non_nullable
as bool,batchFilesJson: freezed == batchFilesJson ? _self.batchFilesJson : batchFilesJson // ignore: cast_nullable_to_non_nullable
as String?,senderHttpHost: freezed == senderHttpHost ? _self.senderHttpHost : senderHttpHost // ignore: cast_nullable_to_non_nullable
as String?,senderHttpPort: freezed == senderHttpPort ? _self.senderHttpPort : senderHttpPort // ignore: cast_nullable_to_non_nullable
as int?,isOutgoing: null == isOutgoing ? _self.isOutgoing : isOutgoing // ignore: cast_nullable_to_non_nullable
as bool,localFilePathsJson: freezed == localFilePathsJson ? _self.localFilePathsJson : localFilePathsJson // ignore: cast_nullable_to_non_nullable
as String?,targetDeviceIdsJson: freezed == targetDeviceIdsJson ? _self.targetDeviceIdsJson : targetDeviceIdsJson // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
