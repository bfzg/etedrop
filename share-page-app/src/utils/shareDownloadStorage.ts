/**
 * 分享下载断点：优先 OPFS 落盘，避免大文件占满内存；不支持时退回内存分片。
 * 通过 lastActivityAt + 定期清理，避免失败/断线后半成品长期占用存储。
 */

const META_PREFIX = 'fastsend-dl-meta:'

/** 无活动超过该时间则清理 OPFS 半成品与 meta（默认 1小时） */
export const STALE_DOWNLOAD_MAX_AGE_MS = 1 * 60 * 60 * 1000

/** 下载过程中刷新 lastActivityAt 的最小间隔，避免频繁写 localStorage */
export const DOWNLOAD_ACTIVITY_TOUCH_INTERVAL_MS = 45 * 1000

export type DownloadSessionMeta = {
  deviceId: string
  shareCode: string
  fileName: string
  fileSize: number
  /** 最后一次写入活动（含 meta 更新、分片写入节流刷新），用于 TTL 清理 */
  lastActivityAt?: number
}

function partialFileName(deviceId: string, shareCode: string): string {
  const d = deviceId.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 48)
  const c = shareCode.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 64)
  return `fs-partial-${d}-${c}`
}

function metaStorageKey(deviceId: string, shareCode: string): string {
  return `${META_PREFIX}${deviceId}:${shareCode}`
}

/** 从 localStorage 的 key 解析 deviceId / shareCode（与 metaStorageKey 互逆，id 内勿含冒号） */
function parseMetaStorageKey(key: string): { deviceId: string; shareCode: string } | null {
  if (!key.startsWith(META_PREFIX)) return null
  const rest = key.slice(META_PREFIX.length)
  const i = rest.indexOf(':')
  if (i <= 0) return null
  return { deviceId: rest.slice(0, i), shareCode: rest.slice(i + 1) }
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
      if (o.lastActivityAt == null || typeof o.lastActivityAt !== 'number') {
        writeSessionMeta(o)
        const again = localStorage.getItem(metaStorageKey(deviceId, shareCode))
        if (again) {
          return JSON.parse(again) as DownloadSessionMeta
        }
      }
      return o
    }
    return null
  } catch {
    return null
  }
}

export function writeSessionMeta(meta: DownloadSessionMeta): void {
  const full: DownloadSessionMeta = {
    ...meta,
    lastActivityAt: Date.now(),
  }
  localStorage.setItem(
    metaStorageKey(meta.deviceId, meta.shareCode),
    JSON.stringify(full),
  )
}

export function clearSessionMeta(deviceId: string, shareCode: string): void {
  localStorage.removeItem(metaStorageKey(deviceId, shareCode))
}

/** 续传下载过程中节流调用，刷新 lastActivityAt，避免长下载被 TTL 误删 */
export function touchDownloadSessionActivity(
  deviceId: string,
  shareCode: string,
): void {
  const m = readSessionMeta(deviceId, shareCode)
  if (!m) return
  writeSessionMeta(m)
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

/**
 * 清理「过期」的 OPFS 半成品与对应 localStorage meta，并删除无 meta 对应的孤儿 fs-partial-* 文件。
 * 应在应用启动时调用一次；过期判定依赖 meta.lastActivityAt。
 */
export async function cleanupStaleOpfsDownloads(
  maxAgeMs: number = STALE_DOWNLOAD_MAX_AGE_MS,
): Promise<void> {
  if (typeof localStorage === 'undefined') return

  const now = Date.now()
  const keys = Object.keys(localStorage).filter((k) => k.startsWith(META_PREFIX))

  for (const key of keys) {
    const parsed = parseMetaStorageKey(key)
    if (!parsed) {
      localStorage.removeItem(key)
      continue
    }
    try {
      const raw = localStorage.getItem(key)
      if (!raw) continue
      const o = JSON.parse(raw) as DownloadSessionMeta
      const last = o.lastActivityAt
      if (last == null || typeof last !== 'number') {
        writeSessionMeta({
          deviceId: parsed.deviceId,
          shareCode: parsed.shareCode,
          fileName: o.fileName ?? '',
          fileSize: typeof o.fileSize === 'number' ? o.fileSize : 0,
        })
        continue
      }
      if (now - last > maxAgeMs) {
        await clearPartialFile(parsed.deviceId, parsed.shareCode)
        localStorage.removeItem(key)
      }
    } catch {
      localStorage.removeItem(key)
    }
  }

  await removeOrphanOpfsPartialFiles()
}

/** 删除仍留在 OPFS 但已无 meta 的 fs-partial-*（例如异常退出后 meta 已删） */
export async function removeOrphanOpfsPartialFiles(): Promise<void> {
  if (!hasOpfs()) return
  const expected = new Set<string>()
  for (const key of Object.keys(localStorage)) {
    if (!key.startsWith(META_PREFIX)) continue
    const p = parseMetaStorageKey(key)
    if (!p) continue
    expected.add(partialFileName(p.deviceId, p.shareCode))
  }
  try {
    const root = await navigator.storage.getDirectory()
    // TS lib 未包含 AsyncIterator，运行时 Chromium OPFS 支持 keys()
    const iter = (root as unknown as { keys(): AsyncIterable<string> }).keys()
    for await (const name of iter) {
      if (!name.startsWith('fs-partial-')) continue
      if (!expected.has(name)) {
        try {
          await root.removeEntry(name)
        } catch {
          /* ignore */
        }
      }
    }
  } catch {
    /* ignore */
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
