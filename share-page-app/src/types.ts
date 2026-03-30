/** 分享信息（DataChannel share-info） */
export interface ShareInfo {
  type: 'share-info'
  fileName: string
  fileSize: number
  hasPassword?: boolean
}

/** 验证结果（DataChannel verify-result） */
export interface VerifyResult {
  type: 'verify-result'
  success: boolean
  error?: string
}

/** 文件元数据（DataChannel file-meta） */
export interface FileMeta {
  type: 'file-meta'
  fileName: string
  fileSize: number
  /** 二进制帧前若干字节为偏移头；8 表示大端 uint64 绝对偏移 + 负载 */
  chunkPrefixBytes?: number
  /** 本连接实际从该字节开始发送（断点续传） */
  resumeFrom?: number
}

/** 文件传输完成（DataChannel file-done） */
export interface FileDone {
  type: 'file-done'
}

/** DataChannel 错误 */
export interface DcError {
  type: 'error'
  message?: string
}

/** 流媒体开始（DataChannel stream-start 的应答/附加信息可后续扩展） */
export interface StreamMeta {
  type: 'stream-meta'
  mime?: string
  codecs?: string
  duration?: number
  binaryMode?: 'raw-mp4' | 'init-segment-v1'
  /** seek 应答时携带，表明本次是从 seek 后的新位置开始 */
  seeked?: boolean
  actualTime?: number
}

/** 流媒体结束 */
export interface StreamDone {
  type: 'stream-done'
}

/** Web -> Desktop: 请求跳转到指定时间 */
export interface StreamSeek {
  type: 'stream-seek'
  targetTime: number
}

/** Desktop -> Web: seek 完成确认 */
export interface StreamSeeked {
  type: 'stream-seeked'
  actualTime: number
}

export type DataChannelMessage =
  | ShareInfo
  | VerifyResult
  | FileMeta
  | FileDone
  | StreamMeta
  | StreamDone
  | StreamSeeked
  | DcError
