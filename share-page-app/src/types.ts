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

export type DataChannelMessage =
  | ShareInfo
  | VerifyResult
  | FileMeta
  | FileDone
  | DcError
