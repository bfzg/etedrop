/**
 * 分片下载应用层确认窗口（payload 字节，不含 8 字节偏移头）。
 * 须与 `fast_send_flutter/.../share_p2p_handler.dart` 中 `_downloadAckWindowBytes` 保持一致。
 *
 * AB（须与 Flutter `SHARE_DOWNLOAD_ACK_WINDOW_BYTES` 一致）:
 * - 默认 8MB
 * - `?ackMb=4` → 4MB，`?ackMb=2` → 2MB
 */
function resolveAckWindowBytes(): number {
  const qs = new URLSearchParams(window.location.search).get("ackMb");
  const mb = Number(qs);
  if (mb === 2) return 2 * 1024 * 1024;
  if (mb === 4) return 4 * 1024 * 1024;
  return 8 * 1024 * 1024;
}

export const DOWNLOAD_ACK_WINDOW_BYTES = resolveAckWindowBytes();
