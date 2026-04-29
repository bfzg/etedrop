import '../../../../core/config/constants.dart';

/// 单帧二进制负载（不含 8 字节偏移头），与 [AppConstants.defaultBlockSize] 对齐。
int get shareP2pDataChunkSize => AppConstants.defaultBlockSize;

/// 从头下载且不超过此大小时走「无偏移头」快速路径。
const int shareP2pSmallFileFastPathMaxBytes = 4 * 1024 * 1024;

/// 小文件尝试单帧发送的上限（超过则改为无头多分片）。
const int shareP2pSmallFileSingleSendMaxBytes = 128 * 1024;

/// 快速路径下无头分片的负载大小。
const int shareP2pSmallFileLegacyChunkBytes = 64 * 1024;

/// 分片下载时发送侧 `bufferedAmount` 超过此值则等待再发下一包。
const int shareP2pDownloadMaxBufferedBytes = int.fromEnvironment(
  'SHARE_DOWNLOAD_MAX_BUFFERED_BYTES',
  defaultValue: 4 * 1024 * 1024,
);

/// 与 share-page-app `DOWNLOAD_ACK_WINDOW_BYTES` 一致。
const int shareP2pDownloadAckWindowBytes = int.fromEnvironment(
  'SHARE_DOWNLOAD_ACK_WINDOW_BYTES',
  defaultValue: 4 * 1024 * 1024,
);

/// 视频流应用层 ACK 窗口（仅 kBinSeg payload 计入）。
const int shareP2pStreamDataAckWindowBytes = int.fromEnvironment(
  'SHARE_STREAM_ACK_WINDOW_BYTES',
  defaultValue: 2 * 1024 * 1024,
);

/// 二进制流媒体帧 v2：`[ver=2][kind:u8][seq:be32][payload...]`。
const int shareP2pStreamBinVersionV2 = 2;
const int shareP2pStreamBinHeaderV2Bytes = 6;
