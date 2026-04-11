/**
 * 分片下载应用层确认窗口（payload 字节，不含 8 字节偏移头）。
 * 须与 `fast_send_flutter/.../share_p2p_handler.dart` 中 `_downloadAckWindowBytes` 保持一致。
 *
 * AB（须与 Flutter `SHARE_DOWNLOAD_ACK_WINDOW_BYTES` 一致）:
 * - 默认 4MB（与 Flutter 默认一致；过大时首段 ack 晚，发送端易长时间 await）
 * - `?ackMb=2` → 2MB，`?ackMb=8` → 8MB
 */
function resolveAckWindowBytes(): number {
  const qs = new URLSearchParams(window.location.search).get("ackMb");
  const mb = Number(qs);
  if (mb === 2) return 2 * 1024 * 1024;
  if (mb === 8) return 8 * 1024 * 1024;
  return 4 * 1024 * 1024;
}

export const DOWNLOAD_ACK_WINDOW_BYTES = resolveAckWindowBytes();
