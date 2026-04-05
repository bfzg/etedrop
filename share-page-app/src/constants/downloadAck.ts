/**
 * 分片下载应用层确认窗口（payload 字节，不含 8 字节偏移头）。
 * 须与 `fast_send_flutter/.../share_p2p_handler.dart` 中 `_downloadAckWindowBytes` 保持一致。
 */
export const DOWNLOAD_ACK_WINDOW_BYTES = 512 * 1024;
