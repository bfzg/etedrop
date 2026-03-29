/**
 * 分享下载断点：优先 OPFS 落盘，避免大文件占满内存；不支持时退回内存分片。
 */

export type DownloadSessionMeta = {
  deviceId: string
  shareCode: string
  fileName: string
  fileSize: number
}

function partialFileName(deviceId: string, shareCode: string): string {
  const d = deviceId.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 48)
  const c = shareCode.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 64)
  return `fs-partial-${d}-${c}`
}

function metaStorageKey(deviceId: string, shareCode: string): string {
  return `fastsend-dl-meta:${deviceId}:${shareCode}`
}

export function readSessionMeta(
  deviceId: string,
  shareCode: string,
): DownloadSessionMeta | null {
  try {
    const raw = localStorage.getItem(metaStorageKey(deviceId, shareCode))
    if (!raw) return null
    const o = JSON.parse(raw) as DownloadSessionMeta
    if (
      o.deviceId === deviceId &&
      o.shareCode === shareCode &&
      typeof o.fileName === 'string' &&
      typeof o.fileSize === 'number'
    ) {
      return o
    }
    return null
  } catch {
    return null
  }
}

export function writeSessionMeta(meta: DownloadSessionMeta): void {
  localStorage.setItem(metaStorageKey(meta.deviceId, meta.shareCode), JSON.stringify(meta))
}

export function clearSessionMeta(deviceId: string, shareCode: string): void {
  localStorage.removeItem(metaStorageKey(deviceId, shareCode))
}

export function hasOpfs(): boolean {
  return (
    typeof navigator !== 'undefined' &&
    !!navigator.storage &&
    typeof navigator.storage.getDirectory === 'function'
  )
}

export async function getOpfsPartialSize(
  deviceId: string,
  shareCode: string,
): Promise<number> {
  if (!hasOpfs()) return 0
  try {
    const root = await navigator.storage.getDirectory()
    const fh = await root.getFileHandle(partialFileName(deviceId, shareCode))
    const file = await fh.getFile()
    return file.size
  } catch {
    return 0
  }
}

/** 与 share-info 不一致时清除本地半成品，避免错续传 */
export async function ensureMetaMatchesOrClear(
  deviceId: string,
  shareCode: string,
  fileName: string,
  fileSize: number,
): Promise<void> {
  const meta = readSessionMeta(deviceId, shareCode)
  if (
    meta &&
    (meta.fileName !== fileName || meta.fileSize !== fileSize)
  ) {
    await clearPartialFile(deviceId, shareCode)
  }
  writeSessionMeta({ deviceId, shareCode, fileName, fileSize })
}

export async function clearPartialFile(
  deviceId: string,
  shareCode: string,
): Promise<void> {
  if (!hasOpfs()) return
  try {
    const root = await navigator.storage.getDirectory()
    await root.removeEntry(partialFileName(deviceId, shareCode))
  } catch {
    /* 不存在则忽略 */
  }
}

/** 单连接内复用一条 Writable，按绝对 offset 写入（与带前缀分片协议一致） */
export class OpfsChunkWriter {
  private writable: FileSystemWritableFileStream | null = null
  private readonly name: string

  constructor(deviceId: string, shareCode: string) {
    this.name = partialFileName(deviceId, shareCode)
  }

  async open(truncate: boolean): Promise<void> {
    if (!hasOpfs()) throw new Error('OPFS unavailable')
    const root = await navigator.storage.getDirectory()
    const fh = await root.getFileHandle(this.name, { create: true })
    this.writable = await fh.createWritable({
      keepExistingData: !truncate,
    })
  }

  async writeAt(offset: number, data: ArrayBuffer): Promise<void> {
    if (!this.writable) throw new Error('OpfsChunkWriter not open')
    await this.writable.seek(offset)
    await this.writable.write(data)
  }

  async close(): Promise<void> {
    if (this.writable) {
      await this.writable.close()
      this.writable = null
    }
  }

  async getBlob(): Promise<Blob> {
    const root = await navigator.storage.getDirectory()
    const fh = await root.getFileHandle(this.name)
    const file = await fh.getFile()
    return file
  }
}

export function parseOffsetPrefixedChunk(buf: ArrayBuffer): {
  offset: number
  data: ArrayBuffer
} {
  if (buf.byteLength < 8) {
    throw new Error('chunk too small')
  }
  const view = new DataView(buf)
  const offset = Number(view.getBigUint64(0, false))
  return { offset, data: buf.slice(8) }
}
