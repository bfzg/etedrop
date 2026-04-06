/**
 * 分片下载应用层确认窗口（payload 字节，不含 8 字节偏移头）。
 * 须与 `fast_send_flutter/.../share_p2p_handler.dart` 中 `_downloadAckWindowBytes` 保持一致。
 *
 * AB:
 * - 默认 4MB（与 Flutter 默认一致）
 * - URL 携带 `?ackMb=2` 可切到 2MB
 */
function resolveAckWindowBytes(): number {
  const qs = new URLSearchParams(window.location.search).get("ackMb");
  const mb = Number(qs);
  if (mb === 2) return 2 * 1024 * 1024;
  return 4 * 1024 * 1024;
}

export const DOWNLOAD_ACK_WINDOW_BYTES = resolveAckWindowBytes();
