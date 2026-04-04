import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import type { FileMeta } from "../types";
import streamSaver from "streamsaver";
import {
  clearPartialFile,
  clearSessionMeta,
  getOpfsPartialSize,
  hasOpfs,
  OpfsChunkWriter,
  parseOffsetPrefixedChunk,
  readSessionMeta,
} from "../utils/shareDownloadStorage";
import { shouldUseStreamSaverSink } from "../utils/downloadSink";

export type DownloadIntent = "download" | "play";
type BinaryMode =
  | "legacy"
  | "prefixed-opfs"
  | "prefixed-memory"
  | "prefixed-streamsaver";

const FLOW_PAUSE_PENDING_BYTES = 8 * 1024 * 1024;
const FLOW_RESUME_PENDING_BYTES = 2 * 1024 * 1024;

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

  const closeOpfsWriter = useCallback(async () => {
    const w = opfsWriterRef.current;
    opfsWriterRef.current = null;
    if (w) {
      try { await w.close(); } catch { /* ignore */ }
    }
  }, []);

  const updateFlowControl = useCallback(() => {
    const pending = pendingWriteBytesRef.current;
    if (!downloadPausedRef.current && pending > FLOW_PAUSE_PENDING_BYTES) {
      downloadPausedRef.current = true;
      sendJson({ type: "download-pause" });
    } else if (downloadPausedRef.current && pending < FLOW_RESUME_PENDING_BYTES) {
      downloadPausedRef.current = false;
      sendJson({ type: "download-resume" });
    }
  }, [sendJson]);

  const resetDownload = useCallback(() => {
    void closeOpfsWriter();
    const sw = streamSaverWriterRef.current;
    streamSaverWriterRef.current = null;
    if (sw) {
      void sw.abort().catch(() => {});
    }
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
  }, [closeOpfsWriter]);

  const handleShareInfo = useCallback(
    (m: { fileName: string; fileSize: number; hasPassword: boolean }) => {
      fileInfoRef.current = m;
      if (hasOpfs()) {
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
      } else {
        setResumeHintBytes(0);
      }
    },
    [deviceId, shareCode],
  );

  const handleFileMeta = useCallback(
    (m: FileMeta) => {
      const prefix = m.chunkPrefixBytes ?? 0;
      const resumeEcho = m.resumeFrom ?? 0;
      totalBytesRef.current = m.fileSize;
      expectedNextOffsetRef.current = resumeEcho;
      setProgress({ received: resumeEcho, total: m.fileSize });
      lastProgressAtMsRef.current = Date.now();
      lastProgressBytesRef.current = resumeEcho;
      setDownloadError("");

      if (prefix === 8) {
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
              const name = fi?.fileName ?? "download";
              const ws = streamSaver.createWriteStream(name, {
                size: m.fileSize,
              });
              streamSaverWriterRef.current = ws.getWriter();
            } catch (e) {
              console.error("[fastsend] streamSaver init failed", e);
              streamSaverWriterRef.current = null;
              try {
                if (hasOpfs()) {
                  binaryModeRef.current = "prefixed-opfs";
                  const w = new OpfsChunkWriter(deviceId, shareCode);
                  await w.open(resumeEcho === 0);
                  opfsWriterRef.current = w;
                } else {
                  binaryModeRef.current = "prefixed-memory";
                }
              } catch {
                binaryModeRef.current = "prefixed-memory";
                opfsWriterRef.current = null;
              }
            } finally {
              releaseGate();
            }
          })();
        } else if (hasOpfs()) {
          binaryModeRef.current = "prefixed-opfs";
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
          releaseGate();
        }
      } else {
        opfsGateRef.current = Promise.resolve();
        binaryModeRef.current = "legacy";
        chunksRef.current = [];
      }

      setShowProgress(true);
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

    pendingWriteBytesRef.current += buf.byteLength;
    updateFlowControl();
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
        pendingWriteBytesRef.current -= buf.byteLength;
        if (pendingWriteBytesRef.current < 0) pendingWriteBytesRef.current = 0;
        updateFlowControl();
      });
  }, [updateFlowControl, t]);

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
      const triggerSave = (blob: Blob) => {
        if (blob.size === 0) return;
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
        await clearPartialFile(deviceId, shareCode);
        clearSessionMeta(deviceId, shareCode);
      } else if (mode === "prefixed-opfs" && opfsWriterRef.current && hasOpfs()) {
        const w = opfsWriterRef.current;
        opfsWriterRef.current = null;
        await w.close();
        const blob = await w.getBlob();
        if (intent === "play") triggerPlay(blob);
        else triggerSave(blob);
        await clearPartialFile(deviceId, shareCode);
        clearSessionMeta(deviceId, shareCode);
      } else if (mode === "prefixed-opfs" || mode === "prefixed-memory") {
        const blob = new Blob(memoryDataChunksRef.current);
        if (intent === "play") triggerPlay(blob);
        else triggerSave(blob);
        memoryDataChunksRef.current = [];
      } else {
        const parts = chunksRef.current;
        if (parts.length === 0) return;
        const blob = new Blob(parts);
        if (intent === "play") triggerPlay(blob);
        else triggerSave(blob);
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
