// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransferMessage _$TransferMessageFromJson(Map<String, dynamic> json) =>
    _TransferMessage(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      senderName: json['senderName'] as String,
      senderDeviceId: json['senderDeviceId'] as String,
      senderAvatar: (json['senderAvatar'] as num?)?.toInt() ?? 1,
      timestamp: (json['timestamp'] as num).toInt(),
      status:
          $enumDecodeNullable(_$TransferMessageStatusEnumMap, json['status']) ??
          TransferMessageStatus.pending,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      errorMessage: json['errorMessage'] as String?,
      shareId: json['shareId'] as String?,
      isBatch: json['isBatch'] as bool? ?? false,
      batchFilesJson: json['batchFilesJson'] as String?,
      senderHttpHost: json['senderHttpHost'] as String?,
      senderHttpPort: (json['senderHttpPort'] as num?)?.toInt(),
      isOutgoing: json['isOutgoing'] as bool? ?? false,
      localFilePathsJson: json['localFilePathsJson'] as String?,
      targetDeviceIdsJson: json['targetDeviceIdsJson'] as String?,
      caption: json['caption'] as String?,
    );

Map<String, dynamic> _$TransferMessageToJson(_TransferMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'senderName': instance.senderName,
      'senderDeviceId': instance.senderDeviceId,
      'senderAvatar': instance.senderAvatar,
      'timestamp': instance.timestamp,
      'status': _$TransferMessageStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'errorMessage': instance.errorMessage,
      'shareId': instance.shareId,
      'isBatch': instance.isBatch,
      'batchFilesJson': instance.batchFilesJson,
      'senderHttpHost': instance.senderHttpHost,
      'senderHttpPort': instance.senderHttpPort,
      'isOutgoing': instance.isOutgoing,
      'localFilePathsJson': instance.localFilePathsJson,
      'targetDeviceIdsJson': instance.targetDeviceIdsJson,
      'caption': instance.caption,
    };

const _$TransferMessageStatusEnumMap = {
  TransferMessageStatus.pending: 'pending',
  TransferMessageStatus.accepted: 'accepted',
  TransferMessageStatus.rejected: 'rejected',
  TransferMessageStatus.receiving: 'receiving',
  TransferMessageStatus.completed: 'completed',
  TransferMessageStatus.failed: 'failed',
  TransferMessageStatus.expired: 'expired',
};
