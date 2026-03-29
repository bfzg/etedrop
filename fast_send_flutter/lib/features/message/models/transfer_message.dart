import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_message.freezed.dart';
part 'transfer_message.g.dart';

enum TransferMessageStatus {
  pending,
  accepted,
  rejected,
  receiving,
  completed,
  failed,
  /// 无人接受超时（接收方）或超时/取消未送出（发送方）
  expired,
}

@freezed
abstract class TransferMessage with _$TransferMessage {
  const factory TransferMessage({
    required String id,
    required String fileName,
    required int fileSize,
    required String senderName,
    required String senderDeviceId,
    @Default(1) int senderAvatar,
    required int timestamp,
    @Default(TransferMessageStatus.pending) TransferMessageStatus status,
    @Default(0.0) double progress,
    String? errorMessage,
    /// 局域网批量分享 ID（与发送方会话一致）
    String? shareId,
    @Default(false) bool isBatch,
    /// JSON 数组：[{"name":"a","size":1},...]
    String? batchFilesJson,
    /// 发送方 HTTP 地址（接收方接受/拒绝时回调）
    String? senderHttpHost,
    int? senderHttpPort,
    /// 本机发出的批量分享（消息列表中展示「发送」侧）
    @Default(false) bool isOutgoing,
    /// JSON 数组：本机绝对路径。发送方用于过期重试；接收方在传输完成后写入落盘路径，供在文件夹中定位。
    String? localFilePathsJson,
    /// JSON 数组：目标 deviceId，用于重试
    String? targetDeviceIdsJson,
  }) = _TransferMessage;

  factory TransferMessage.fromJson(Map<String, dynamic> json) =>
      _$TransferMessageFromJson(json);
}
