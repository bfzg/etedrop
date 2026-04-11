import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import type { FileMeta } from "../types";
import streamSaver from "../lib/streamSaver";
import {
  clearPartialFile,
  clearSessionMeta,
  DOWNLOAD_ACTIVITY_TOUCH_INTERVAL_MS,
  getOpfsPartialSize,
  hasOpfs,
  OpfsChunkWriter,
  parseOffsetPrefixedChunk,
  readSessionMeta,
  touchDownloadSessionActivity,
} from "../utils/shareDownloadStorage";
import { DOWNLOAD_ACK_WINDOW_BYTES } from "../constants/downloadAck";
import { p2pLog } from "../utils/p2pDebug";
import {
  shouldUseOpfsResumeFromPartial,
  shouldUseStreamSaverSink,
  trySaveBlobViaFileSystemPicker,
  uniqueStreamSaverFileName,
} from "../utils/downloadSink";

export type DownloadIntent = "download" | "play";
type BinaryMode =
  | "legacy"
  | "prefixed-opfs"
  | "prefixed-memory"
  | "prefixed-streamsaver";

/** 待写入队列超过此值则通知发送端 pause（与 Flutter `_downloadFlowGate` 对应） */
const FLOW_PAUSE_PENDING_BYTES = 8 * 1024 * 1024;
/**
 * resume 低于 pause，留滞后带，避免在 8MB 边界上 pause/resume 来回抖动。
 * 若 resume 过小（如 4MB），慢写入时 pending 会长期停在 4～8MB 无法 resume（旧问题）。
 * 若 resume 与 pause 同为 8MB（pending<=8 即 resume），易高频震荡，且端到端易出现「差几 MB 卡住」。
 */
const FLOW_RESUME_PENDING_BYTES = 6 * 1024 * 1024;
/** 仍显示 paused 但 pending 已低于 pause 线时，周期性补发 resume（信令丢失或 6～8MB 死区） */
const FLOW_RESUME_WATCHDOG_MS = 800;

export function useDownload(
  deviceId: string,
  shareCode: string,
  sendJson: (data: unknown) => void,
) {
  const { t } = useTranslation();
  const [showProgress, setShowProgress] = useState(false);
  const [progress, setProgress] = useState({ received: 0, total: 0 });
  const [showDone, setShowDone] = useState(false);
  const [doneKind, setDoneKind] = useState<"" | "download" | "stream">("");
  const [resumeHintBytes, setResumeHintBytes] = useState(0);
  const [playUrl, setPlayUrl] = useState<string>("");
  const [downloadError, setDownloadError] = useState<string>("");

  const chunksRef = useRef<ArrayBuffer[]>([]);
  const memoryDataChunksRef = useRef<ArrayBuffer[]>([]);
  const totalBytesRef = useRef(0);
  const expectedNextOffsetRef = useRef(0);
  const binaryModeRef = useRef<BinaryMode>("legacy");
  const opfsWriterRef = useRef<OpfsChunkWriter | null>(null);
  const streamSaverWriterRef =
    useRef<WritableStreamDefaultWriter<Uint8Array> | null>(null);
  const opfsGateRef = useRef(Promise.resolve());
  const writeChainRef = useRef(Promise.resolve());
  const pendingWriteBytesRef = useRef(0);
  const downloadPausedRef = useRef(false);
  const downloadCompletedRef = useRef(false);
  const lastProgressAtMsRef = useRef<number>(0);
  const lastProgressBytesRef = useRef<number>(0);
  const downloadIntentRef = useRef<DownloadIntent>("download");
  const fileInfoRef = useRef<{
    fileName: string;
    fileSize: number;
    hasPassword: boolean;
  } | null>(null);
  const playUrlRef = useRef<string>("");
  /** 节流刷新 OPFS 会话 lastActivityAt，避免长下载被 TTL 清理 */
  const lastOpfsActivityTouchAtRef = useRef(0);
  const flowPauseBytesRef = useRef(FLOW_PAUSE_PENDING_BYTES);
  const flowResumeBytesRef = useRef(FLOW_RESUME_PENDING_BYTES);
  /** 与 Flutter `_downloadAckWindowBytes` 对齐；落盘后回传 `download-ack` */
  const bytesSinceAckRef = useRef(0);

  const closeOpfsWriter = useCallback(async () => {
    const w = opfsWriterRef.current;
    opfsWriterRef.current = null;
    if (w) {
      try { await w.close(); } catch { /* ignore */ }
    }
  }, []);

  const updateFlowControl = useCallback(() => {
    if (binaryModeRef.current === "prefixed-streamsaver") {
      return;
    }
    const pending = pendingWriteBytesRef.current;
    const pauseAt = flowPauseBytesRef.current;
    const resumeBelow = flowResumeBytesRef.current;
    if (!downloadPausedRef.current && pending > pauseAt) {
      downloadPausedRef.current = true;
      p2pLog("flow-control pause", { pending, pauseAt });
      sendJson({ type: "download-pause" });
    } else if (
      downloadPausedRef.current &&
      pending < resumeBelow
    ) {
      downloadPausedRef.current = false;
      p2pLog("flow-control resume", { pending, resumeBelow });
      sendJson({ type: "download-resume" });
    }
  }, [sendJson]);

  /** 补发 resume：避免 pause/resume JSON 丢失；主逻辑仅在 pending<6MB 时 resume，6～8MB 区间靠此兜底 */
  useEffect(() => {
    const id = window.setInterval(() => {
      if (downloadCompletedRef.current) return;
      if (totalBytesRef.current <= 0) return;
      if (!downloadPausedRef.current) return;
      const pending = pendingWriteBytesRef.current;
      if (pending < flowPauseBytesRef.current) {
        downloadPausedRef.current = false;
        p2pLog("flow-control resume (watchdog)", { pending });
        sendJson({ type: "download-resume" });
      }
    }, FLOW_RESUME_WATCHDOG_MS);
    return () => window.clearInterval(id);
  }, [sendJson]);

  const resetDownload = useCallback(() => {
    void closeOpfsWriter();
    const sw = streamSaverWriterRef.current;
    streamSaverWriterRef.current = null;
    if (sw) {
      void sw.abort().catch(() => {});
    }
    streamSaver.resetMitmTransporter();
    flowPauseBytesRef.current = FLOW_PAUSE_PENDING_BYTES;
    flowResumeBytesRef.current = FLOW_RESUME_PENDING_BYTES;
    bytesSinceAckRef.current = 0;
    writeChainRef.current = Promise.resolve();
    opfsGateRef.current = Promise.resolve();
    pendingWriteBytesRef.current = 0;
    downloadPausedRef.current = false;
    lastProgressAtMsRef.current = Date.now();
    lastProgressBytesRef.current = 0;
    setDownloadError("");
    setShowProgress(false);
    setProgress({ received: 0, total: 0 });
    setShowDone(false);
    setDoneKind("");
    setResumeHintBytes(0);
    chunksRef.current = [];
    memoryDataChunksRef.current = [];
    totalBytesRef.current = 0;
    expectedNextOffsetRef.current = 0;
    binaryModeRef.current = "legacy";
    downloadCompletedRef.current = false;
    downloadIntentRef.current = "download";

    if (playUrlRef.current) {
      try { URL.revokeObjectURL(playUrlRef.current); } catch { /* ignore */ }
    }
    playUrlRef.current = "";
    setPlayUrl("");
    lastOpfsActivityTouchAtRef.current = 0;
  }, [closeOpfsWriter]);

  const handleShareInfo = useCallback(
    (m: { fileName: string; fileSize: number; hasPassword: boolean }) => {
      fileInfoRef.current = m;
      if (!shouldUseOpfsResumeFromPartial()) {
        setResumeHintBytes(0);
        return;
      }
      void (async () => {
        const meta = readSessionMeta(deviceId, shareCode);
        const fi = fileInfoRef.current;
        if (!fi || !meta || meta.fileName !== fi.fileName || meta.fileSize !== fi.fileSize) {
          setResumeHintBytes(0);
          return;
        }
        const n = await getOpfsPartialSize(deviceId, shareCode);
        setResumeHintBytes(n > 0 && n < fi.fileSize ? n : 0);
      })();
    },
    [deviceId, shareCode],
  );

  const handleFileMeta = useCallback(
    (m: FileMeta) => {
      const prefix = m.chunkPrefixBytes ?? 0;
      /** StreamSaver 不做续传：忽略对端的 resumeFrom，始终从 0 接收 */
      const resumeEcho = shouldUseStreamSaverSink()
        ? 0
        : (m.resumeFrom ?? 0);
      totalBytesRef.current = m.fileSize;
      expectedNextOffsetRef.current = resumeEcho;
      setProgress({ received: resumeEcho, total: m.fileSize });
      lastProgressAtMsRef.current = Date.now();
      lastProgressBytesRef.current = resumeEcho;
      setDownloadError("");

      if (prefix === 8) {
        bytesSinceAckRef.current = 0;
        memoryDataChunksRef.current = [];
        let releaseGate!: () => void;
        opfsGateRef.current = new Promise<void>((r) => {
          releaseGate = r;
        });

        const wantStreamSaver = shouldUseStreamSaverSink();

        if (wantStreamSaver) {
          binaryModeRef.current = "prefixed-streamsaver";
          void (async () => {
            try {
              await closeOpfsWriter();
              const fi = fileInfoRef.current;
              const name = uniqueStreamSaverFileName(fi?.fileName ?? "download");
              const ws = streamSaver.createWriteStream(name, {
                size: m.fileSize,
                // Allow up to 64 chunks (64 × 64 KB ≈ 4 MB) to be buffered in the
                // TransformStream before backpressure kicks in. Without this, the
                // default highWaterMark of 1 means every `await w.write(chunk)` in the
                // write chain must wait for the SW/browser to pull that specific chunk
                // before resolving, making writes as slow as the download consumer.
                // With 64, the write chain can process a full ACK window without blocking.
                writableStrategy: { highWaterMark: 64 },
                readableStrategy: { highWaterMark: 64 },
              });
              streamSaverWriterRef.current = ws.getWriter();
            } catch (e) {
              console.error("[fastsend] streamSaver init failed", e);
              streamSaverWriterRef.current = null;
              streamSaver.resetMitmTransporter();
              try {
                if (hasOpfs()) {
                  binaryModeRef.current = "prefixed-opfs";
                  flowPauseBytesRef.current = FLOW_PAUSE_PENDING_BYTES;
                  flowResumeBytesRef.current = FLOW_RESUME_PENDING_BYTES;
                  const w = new OpfsChunkWriter(deviceId, shareCode);
                  await w.open(resumeEcho === 0);
                  opfsWriterRef.current = w;
                } else {
                  binaryModeRef.current = "prefixed-memory";
                  flowPauseBytesRef.current = FLOW_PAUSE_PENDING_BYTES;
                  flowResumeBytesRef.current = FLOW_RESUME_PENDING_BYTES;
                }
              } catch {
                binaryModeRef.current = "prefixed-memory";
                flowPauseBytesRef.current = FLOW_PAUSE_PENDING_BYTES;
                flowResumeBytesRef.current = FLOW_RESUME_PENDING_BYTES;
                opfsWriterRef.current = null;
              }
            } finally {
              releaseGate();
            }
          })();
        } else if (hasOpfs()) {
          binaryModeRef.current = "prefixed-opfs";
          flowPauseBytesRef.current = FLOW_PAUSE_PENDING_BYTES;
          flowResumeBytesRef.current = FLOW_RESUME_PENDING_BYTES;
          void (async () => {
            try {
              await closeOpfsWriter();
              const w = new OpfsChunkWriter(deviceId, shareCode);
              await w.open(resumeEcho === 0);
              opfsWriterRef.current = w;
            } catch {
              binaryModeRef.current = "prefixed-memory";
              opfsWriterRef.current = null;
            } finally {
              releaseGate();
            }
          })();
        } else {
          binaryModeRef.current = "prefixed-memory";
          flowPauseBytesRef.current = FLOW_PAUSE_PENDING_BYTES;
          flowResumeBytesRef.current = FLOW_RESUME_PENDING_BYTES;
          releaseGate();
        }
      } else {
        opfsGateRef.current = Promise.resolve();
        binaryModeRef.current = "legacy";
        chunksRef.current = [];
      }

      setShowProgress(true);
      p2pLog("file-meta", {
        chunkPrefixBytes: prefix,
        resumeEcho,
        fileSize: m.fileSize,
        ackWindowBytes: DOWNLOAD_ACK_WINDOW_BYTES,
      });
    },
    [closeOpfsWriter, deviceId, shareCode],
  );

  const handleBinaryChunk = useCallback((buf: ArrayBuffer) => {
    const mode = binaryModeRef.current;

    if (mode === "legacy") {
      chunksRef.current.push(buf);
      const total = totalBytesRef.current || 1;
      const received = chunksRef.current.reduce(
        (acc, c) => acc + c.byteLength,
        0,
      );
      setProgress((p) => ({ ...p, received, total }));
      lastProgressAtMsRef.current = Date.now();
      lastProgressBytesRef.current = received;
      return;
    }

    const pendingWeight = buf.byteLength;
    pendingWriteBytesRef.current += pendingWeight;
    updateFlowControl();

    // Send ACK immediately upon receive, decoupled from write-chain completion.
    // Previously the ACK was sent inside the write chain after `await w.write()`, which
    // forced Flutter to stop-and-wait for the entire serial write pipeline (TransformStream
    // IPC to the Service Worker) before sending the next window. This capped throughput
    // to ~100 KB/s even on fast networks.
    // dataBytes = actual file content (buf.byteLength minus the 8-byte offset prefix).
    if (
      mode === "prefixed-opfs" ||
      mode === "prefixed-streamsaver" ||
      mode === "prefixed-memory"
    ) {
      const dataBytes = buf.byteLength > 8 ? buf.byteLength - 8 : 0;
      bytesSinceAckRef.current += dataBytes;
      if (bytesSinceAckRef.current >= DOWNLOAD_ACK_WINDOW_BYTES) {
        p2pLog("send download-ack (window-rx)", {
          ackWindowBytes: DOWNLOAD_ACK_WINDOW_BYTES,
          pendingWriteQueueApprox: pendingWriteBytesRef.current,
        });
        sendJson({ type: "download-ack" });
        bytesSinceAckRef.current = 0;
      }
    }

    writeChainRef.current = writeChainRef.current
      .then(async () => {
        await opfsGateRef.current;
        const { offset, data } = parseOffsetPrefixedChunk(buf);
        if (offset !== expectedNextOffsetRef.current) {
          console.warn("[fastsend] chunk offset mismatch", offset, expectedNextOffsetRef.current);
          setDownloadError(
            t("download.chunkMismatch", {
              got: offset,
              expected: expectedNextOffsetRef.current,
            }),
          );
          return;
        }
        if (binaryModeRef.current === "prefixed-opfs") {
          const w = opfsWriterRef.current;
          if (w) {
            await w.writeAt(offset, data);
          } else {
            memoryDataChunksRef.current.push(data);
          }
        } else if (binaryModeRef.current === "prefixed-streamsaver") {
          const w = streamSaverWriterRef.current;
          if (w) {
            await w.write(new Uint8Array(data));
          } else {
            memoryDataChunksRef.current.push(data);
          }
        } else {
          memoryDataChunksRef.current.push(data);
        }
        expectedNextOffsetRef.current += data.byteLength;
        const totalBytes = totalBytesRef.current;
        setProgress({ received: expectedNextOffsetRef.current, total: totalBytes });
        lastProgressAtMsRef.current = Date.now();
        lastProgressBytesRef.current = expectedNextOffsetRef.current;

        // Window ACKs are now sent outside the chain (immediately on receive).
        // Only handle the final-partial ACK here, where we can confirm the file is complete.
        const ackMode = binaryModeRef.current;
        if (
          (ackMode === "prefixed-opfs" ||
            ackMode === "prefixed-streamsaver" ||
            ackMode === "prefixed-memory") &&
          expectedNextOffsetRef.current >= totalBytes &&
          bytesSinceAckRef.current > 0
        ) {
          p2pLog("send download-ack (final partial)", {
            tailBytes: bytesSinceAckRef.current,
            receivedTotal: expectedNextOffsetRef.current,
          });
          sendJson({ type: "download-ack" });
          bytesSinceAckRef.current = 0;
        }

        if (binaryModeRef.current === "prefixed-opfs") {
          const now = Date.now();
          if (
            now - lastOpfsActivityTouchAtRef.current >=
            DOWNLOAD_ACTIVITY_TOUCH_INTERVAL_MS
          ) {
            lastOpfsActivityTouchAtRef.current = now;
            touchDownloadSessionActivity(deviceId, shareCode);
          }
        }
      })
      .catch((e) => {
        console.error("[fastsend] write chunk", e);
        setDownloadError(
          t("download.writeFailed", {
            message:
              e && (e as Error).message
                ? (e as Error).message
                : String(e),
          }),
        );
      })
      .finally(() => {
        pendingWriteBytesRef.current -= pendingWeight;
        if (pendingWriteBytesRef.current < 0) pendingWriteBytesRef.current = 0;
        updateFlowControl();
      });
  }, [deviceId, shareCode, updateFlowControl, t, sendJson]);

  // Watchdog: if progress stops increasing for too long, surface it in UI.
  useEffect(() => {
    if (!showProgress) return;
    if (downloadCompletedRef.current) return;
    const id = setInterval(() => {
      if (!showProgress) return;
      if (downloadCompletedRef.current) return;
      const now = Date.now();
      const lastAt = lastProgressAtMsRef.current;
      const lastBytes = lastProgressBytesRef.current;
      const stuckForMs = now - lastAt;
      // If we haven't advanced for 12s, consider it stalled.
      if (stuckForMs > 12_000 && progress.received === lastBytes) {
        setDownloadError(t("download.stalled"));
      }
    }, 2000);
    return () => clearInterval(id);
  }, [showProgress, progress.received, t]);

  const finishDownload = useCallback(async () => {
    await writeChainRef.current.catch(() => {});
    await opfsGateRef.current.catch(() => {});
    const fi = fileInfoRef.current;
    const mode = binaryModeRef.current;
    const intent = downloadIntentRef.current;

    try {
      /** 先尝试 File System Access「另存为」（Chrome 对纯 blob 锚点常误报网络错误），再回退 <a download> */
      const saveWithPickerOrAnchor = async (blob: Blob) => {
        if (blob.size === 0) return;
        const viaPicker = await trySaveBlobViaFileSystemPicker(
          blob,
          fi?.fileName ?? "download",
        );
        if (viaPicker !== "unavailable") return;
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.download = fi?.fileName ?? "download";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        setTimeout(() => URL.revokeObjectURL(url), 5000);
      };

      const triggerPlay = (blob: Blob) => {
        if (blob.size === 0) return;
        const url = URL.createObjectURL(blob);
        if (playUrlRef.current) {
          try { URL.revokeObjectURL(playUrlRef.current); } catch { /* ignore */ }
        }
        playUrlRef.current = url;
        setPlayUrl(url);
      };

      if (mode === "prefixed-streamsaver") {
        const w = streamSaverWriterRef.current;
        streamSaverWriterRef.current = null;
        if (w) {
          try {
            await w.close();
          } catch {
            /* ignore */
          }
        }
        streamSaver.resetMitmTransporter();
        await clearPartialFile(deviceId, shareCode);
        clearSessionMeta(deviceId, shareCode);
      } else if (mode === "prefixed-opfs" && opfsWriterRef.current && hasOpfs()) {
        const w = opfsWriterRef.current;
        opfsWriterRef.current = null;
        await w.close();
        const blob = await w.getBlob();
        if (intent === "play") triggerPlay(blob);
        else await saveWithPickerOrAnchor(blob);
        await clearPartialFile(deviceId, shareCode);
        clearSessionMeta(deviceId, shareCode);
      } else if (mode === "prefixed-opfs" || mode === "prefixed-memory") {
        const blob = new Blob(memoryDataChunksRef.current);
        if (intent === "play") triggerPlay(blob);
        else await saveWithPickerOrAnchor(blob);
        memoryDataChunksRef.current = [];
      } else {
        const parts = chunksRef.current;
        if (parts.length === 0) return;
        const blob = new Blob(parts);
        if (intent === "play") triggerPlay(blob);
        else await saveWithPickerOrAnchor(blob);
        chunksRef.current = [];
      }
    } finally {
      setShowProgress(false);
      setShowDone(true);
      setDoneKind("download");
    }
  }, [deviceId, shareCode]);

  const setDownloadDone = useCallback((kind: "" | "download" | "stream") => {
    setShowDone(true);
    setDoneKind(kind);
  }, []);

  return {
    showProgress,
    setShowProgress,
    progress,
    setProgress,
    showDone,
    setShowDone,
    doneKind,
    setDoneKind,
    resumeHintBytes,
    playUrl,
    downloadError,
    downloadCompletedRef,
    downloadIntentRef,
    totalBytesRef,
    fileInfoRef,
    closeOpfsWriter,
    handleShareInfo,
    handleFileMeta,
    handleBinaryChunk,
    finishDownload,
    resetDownload,
    setDownloadDone,
  };
}
