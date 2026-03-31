import { useCallback, useRef, useState } from "react";
import type { FileMeta } from "../types";
import {
  clearPartialFile,
  clearSessionMeta,
  getOpfsPartialSize,
  hasOpfs,
  OpfsChunkWriter,
  parseOffsetPrefixedChunk,
  readSessionMeta,
} from "../utils/shareDownloadStorage";

export type DownloadIntent = "download" | "play";
type BinaryMode = "legacy" | "prefixed-opfs" | "prefixed-memory";

export function useDownload(deviceId: string, shareCode: string) {
  const [showProgress, setShowProgress] = useState(false);
  const [progress, setProgress] = useState({ received: 0, total: 0 });
  const [showDone, setShowDone] = useState(false);
  const [doneKind, setDoneKind] = useState<"" | "download" | "stream">("");
  const [resumeHintBytes, setResumeHintBytes] = useState(0);
  const [playUrl, setPlayUrl] = useState<string>("");

  const chunksRef = useRef<ArrayBuffer[]>([]);
  const memoryDataChunksRef = useRef<ArrayBuffer[]>([]);
  const totalBytesRef = useRef(0);
  const expectedNextOffsetRef = useRef(0);
  const binaryModeRef = useRef<BinaryMode>("legacy");
  const opfsWriterRef = useRef<OpfsChunkWriter | null>(null);
  const opfsGateRef = useRef(Promise.resolve());
  const writeChainRef = useRef(Promise.resolve());
  const downloadCompletedRef = useRef(false);
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

  const resetDownload = useCallback(() => {
    void closeOpfsWriter();
    writeChainRef.current = Promise.resolve();
    opfsGateRef.current = Promise.resolve();
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

      if (prefix === 8) {
        memoryDataChunksRef.current = [];
        let releaseGate!: () => void;
        opfsGateRef.current = new Promise<void>((r) => {
          releaseGate = r;
        });

        if (hasOpfs()) {
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
      return;
    }

    writeChainRef.current = writeChainRef.current
      .then(async () => {
        await opfsGateRef.current;
        const { offset, data } = parseOffsetPrefixedChunk(buf);
        if (offset !== expectedNextOffsetRef.current) {
          console.warn("[fastsend] chunk offset mismatch", offset, expectedNextOffsetRef.current);
          return;
        }
        if (binaryModeRef.current === "prefixed-opfs") {
          const w = opfsWriterRef.current;
          if (w) {
            await w.writeAt(offset, data);
          } else {
            memoryDataChunksRef.current.push(data);
          }
        } else {
          memoryDataChunksRef.current.push(data);
        }
        expectedNextOffsetRef.current += data.byteLength;
        const t = totalBytesRef.current;
        setProgress({ received: expectedNextOffsetRef.current, total: t });
      })
      .catch((e) => {
        console.error("[fastsend] write chunk", e);
      });
  }, []);

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

      if (mode === "prefixed-opfs" && opfsWriterRef.current && hasOpfs()) {
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
