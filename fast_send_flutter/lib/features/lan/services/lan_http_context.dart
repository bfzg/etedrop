/// 上传请求上下文（供接收端判断是否允许写入）
class LanUploadContext {
  final String fileName;
  final int fileSize;
  final String senderName;
  final int senderAvatar;
  final String senderDeviceId;
  final String? shareId;
  final int fileIndex;
  final int fileCount;
  final int batchTotalBytes;

  /// 仅在 [onComplete] 回调中由服务端填入，表示已落盘的绝对路径。
  final String? savedAbsolutePath;

  const LanUploadContext({
    required this.fileName,
    required this.fileSize,
    required this.senderName,
    required this.senderAvatar,
    this.senderDeviceId = '',
    this.shareId,
    this.fileIndex = 0,
    this.fileCount = 1,
    this.batchTotalBytes = 0,
    this.savedAbsolutePath,
  });
}
