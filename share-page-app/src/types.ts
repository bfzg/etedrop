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
  fileSize: number
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
