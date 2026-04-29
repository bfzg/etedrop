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
  width?: number
  height?: number
  binaryMode?: 'raw-mp4' | 'init-segment-v1' | 'init-segment-v2'
  /** seek 应答时携带，表明本次是从 seek 后的新位置开始 */
  seeked?: boolean
  /** 「断流续播」应答：sender 收到带 resumeFrom 的 stream-start 后会标记此位，
   *  网页侧需保留既有 SourceBuffer，仅清空 mp4 box 解析状态/SB.buffered。 */
  resume?: boolean
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

/** Web -> Desktop: 流媒体数据接收确认（应用层窗口） */
export interface StreamDataAck {
  type: 'stream-data-ack'
  bytes?: number
  /** 已处理到的最大 wire seq（init-segment-v2 / 带 v2 帧的 v1），与 sender 侧 await 对齐 */
  upToSeq?: number
}

export type DataChannelMessage =
  | ShareInfo
  | VerifyResult
  | FileMeta
  | FileDone
  | StreamMeta
  | StreamDone
  | StreamSeeked
  | StreamDataAck
  | DcError
