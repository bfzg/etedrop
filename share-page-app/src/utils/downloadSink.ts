import { isMobile, isSafari } from "./env";
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
 * **Safari** 与 **手机 UA**（`isMobile`）：在安全上下文 + SW 可用时固定走 StreamSaver，减少 OPFS 在移动端的差异与收尾问题。
 * **桌面非 Safari**：有 OPFS 时优先 OPFS；无 OPFS 且环境可用时用 StreamSaver，否则内存分片。
 * StreamSaver 不做断点续传；每次下载结束或 `resetDownload` 时须 `resetMitmTransporter()`（见 `src/lib/streamSaver`）。
 */
export function shouldUseStreamSaverSink(): boolean {
  if (!isStreamSaverEnvironmentOk()) return false;
  // if (isSafari() || isMobile()) return true;
  // if (hasOpfs()) return false;
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

/** 保存对话框建议文件名（去掉路径与非法字符） */
export function sanitizeDownloadFileName(name: string): string {
  const s = name.replace(/[/\\?%*:|"<>]/g, "_").trim();
  return s.length > 0 ? s : "download";
}

/**
 * Chrome 等在「P2P/写入完成后的异步时刻」用 blob: + 程序化点击 <a download> 保存时，
 * 常误报「无法下载 / 请检查互联网链接状态」（无用户手势）。支持时优先用系统「另存为」+ 流式 pipe。
 *
 * @returns `saved` 已写入；`aborted` 用户取消；`unavailable` 应回退锚点下载
 */
export async function trySaveBlobViaFileSystemPicker(
  data: Blob,
  suggestedName: string,
): Promise<"saved" | "aborted" | "unavailable"> {
  if (typeof window === "undefined") return "unavailable";
  const w = window as Window & {
    showSaveFilePicker?: (options: {
      suggestedName?: string;
    }) => Promise<FileSystemFileHandle>;
  };
  if (typeof w.showSaveFilePicker !== "function") return "unavailable";
  const name = sanitizeDownloadFileName(suggestedName);
  try {
    const handle = await w.showSaveFilePicker({ suggestedName: name });
    const writable = await handle.createWritable();
    await data.stream().pipeTo(writable);
    return "saved";
  } catch (e) {
    if (e instanceof DOMException && e.name === "AbortError") return "aborted";
    console.warn("[fastsend] showSaveFilePicker failed", e);
    return "unavailable";
  }
}
