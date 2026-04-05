import { hasOpfs } from "./shareDownloadStorage";

/**
 * StreamSaver（自托管 mitm + SW）仅在**安全上下文**下可用：
 * - HTTPS，或 localhost / 127.0.0.1
 * - 纯 HTTP 公网 IP/域名（如 http://api.xxx:40321）下 `isSecureContext === false`，
 *   Service Worker 无法注册，会出现小窗口但无法完成下载——此时必须回退 OPFS/内存，并建议上 HTTPS。
 */
export function isStreamSaverEnvironmentOk(): boolean {
  if (typeof window === "undefined") return false;
  if (!window.isSecureContext) return false;
  if (!("serviceWorker" in navigator)) return false;
  return true;
}

/**
 * 当前环境是否使用 StreamSaver（mitm + SW）作为分片下载落盘。
 * **优先 OPFS**：有 OPFS 时一律不用 StreamSaver；仅在无 OPFS 且安全上下文 + SW 可用时用 StreamSaver，否则再走内存分片。
 * StreamSaver 不做断点续传；每次下载结束或 `resetDownload` 时须 `resetMitmTransporter()`（见 `src/lib/streamSaver`）。
 */
export function shouldUseStreamSaverSink(): boolean {
  if (!isStreamSaverEnvironmentOk()) return false;
  if (hasOpfs()) return false;
  return true;
}

/**
 * 是否允许使用 OPFS 半成品 + `resumeFrom` 断点续传（仅当本次实际走 OPFS 落盘时）。
 * StreamSaver 路径为 false：不下发续传字节、`download-start` 始终 `resumeFrom: 0`。
 */
export function shouldUseOpfsResumeFromPartial(): boolean {
  if (!hasOpfs()) return false;
  if (shouldUseStreamSaverSink()) return false;
  return true;
}

/**
 * 为 StreamSaver 下载名加时间戳，避免与「下载」目录已有同名文件冲突。
 * 否则 Android Chrome 等会弹出「是否再次下载」并可能挂起页面或打断 WritableStream。
 */
export function uniqueStreamSaverFileName(baseName: string): string {
  const ts = Date.now();
  const i = baseName.lastIndexOf(".");
  if (i <= 0 || i === baseName.length - 1) {
    return `${baseName}_${ts}`;
  }
  return `${baseName.slice(0, i)}_${ts}${baseName.slice(i)}`;
}
