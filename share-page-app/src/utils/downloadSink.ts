import { isMobile } from "./env";
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
 * 下载落盘策略：
 * - 桌面且支持 OPFS：优先 OPFS。
 * - 手机或无 OPFS：在**环境支持 SW**时用自托管 StreamSaver；否则 OPFS 或内存。
 */
export function shouldUseStreamSaverSink(): boolean {
  if (!isStreamSaverEnvironmentOk()) return false;
  return isMobile() || !hasOpfs();
}
