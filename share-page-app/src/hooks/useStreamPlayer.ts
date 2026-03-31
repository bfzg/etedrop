import { useCallback, useRef, useState } from "react";
import type { StatusKind } from "./useSignaling";
import { concatU8, splitMp4Boxes } from "../utils/mp4Utils";

export type StreamMode = "none" | "mse-fmp4";
export type StreamBinaryMode = "raw-mp4" | "init-segment-v1";

export interface StreamPlayerApi {
  mseUrl: string;
  streaming: boolean;
  streamDuration: number;
  startMse: () => void;
  handleStreamMeta: (m: {
    mime?: string;
    codecs?: string;
    duration?: number;
    binaryMode?: string;
    seeked?: boolean;
    actualTime?: number;
  }) => void;
  handleStreamBinary: (buf: ArrayBuffer) => void;
  handleStreamDone: () => void;
  handleStreamSeeked: () => void;
  sendSeek: (targetTime: number) => void;
  resetStream: () => void;
  streamModeRef: React.RefObject<StreamMode>;
  pumpMse: () => void;
  setStreamProgress: (bytes: number) => void;
}

export function useStreamPlayer(
  sendJson: (data: unknown) => void,
  setStatusState: (kind: StatusKind, text: string) => void,
  setShowReconnect: (v: boolean) => void,
  onStreamEnd: () => void,
) {
  const [mseUrl, setMseUrl] = useState<string>("");
  const [streaming, setStreaming] = useState(false);
  const [streamDuration, setStreamDuration] = useState(0);

  const streamModeRef = useRef<StreamMode>("none");
  const mediaSourceRef = useRef<MediaSource | null>(null);
  const sourceBufferRef = useRef<SourceBuffer | null>(null);
  const desiredMimeRef = useRef<string>("");
  const streamBinaryModeRef = useRef<StreamBinaryMode>("raw-mp4");
  const streamEndedRef = useRef(false);
  const mseQueueRef = useRef<Uint8Array[]>([]);
  const mseBufRef = useRef<Uint8Array>(new Uint8Array(0));
  const mseInitDoneRef = useRef(false);
  const mseInitAccRef = useRef<Uint8Array>(new Uint8Array(0));
  const msePendingMoofRef = useRef<Uint8Array>(new Uint8Array(0));
  const mseSawMoovRef = useRef(false);
  const mseReadyRef = useRef(false);
  const mseUrlRef = useRef<string>("");
  const streamDurationRef = useRef<number>(0);
  const seekingRef = useRef(false);

  const pumpMse = useCallback(() => {
    const sb = sourceBufferRef.current;
    if (!sb) return;
    if (!mseReadyRef.current) return;
    if (sb.updating) return;
    const q = mseQueueRef.current;
    if (q.length === 0) {
      if (streamEndedRef.current) {
        try { mediaSourceRef.current?.endOfStream(); } catch { /* ignore */ }
        onStreamEnd();
        setStreaming(false);
        streamEndedRef.current = false;
      }
      return;
    }
    const maxBatch = 1024 * 1024;
    let totalSize = 0;
    let count = 0;
    while (count < q.length && totalSize < maxBatch) {
      totalSize += q[count].byteLength;
      count++;
    }
    const items = q.splice(0, count);
    try {
      const merged = new Uint8Array(totalSize);
      let off = 0;
      for (const it of items) {
        merged.set(it, off);
        off += it.byteLength;
      }
      sb.appendBuffer(merged);
    } catch (e) {
      console.error(
        "[fastsend] mse append error", e,
        "batchItems:", items.length,
        "batchSize:", totalSize,
        "readyState:", mediaSourceRef.current?.readyState,
      );
    }
  }, [onStreamEnd]);

  const ensureSourceBuffer = useCallback(
    (ms: MediaSource, mime: string) => {
      if (sourceBufferRef.current) return true;
      console.log("[fastsend] ensureSourceBuffer: creating with mime:", mime);
      if (!MediaSource.isTypeSupported(mime)) {
        console.warn("[fastsend] ensureSourceBuffer: mime NOT supported:", mime);
        return false;
      }
      const sb = ms.addSourceBuffer(mime);
      sourceBufferRef.current = sb;
      sb.mode = "segments";
      sb.addEventListener("updateend", () => { pumpMse(); });
      sb.addEventListener("error", (e) => {
        console.error("[fastsend] SourceBuffer error event:", e);
      });
      mseReadyRef.current = true;
      pumpMse();
      return true;
    },
    [pumpMse],
  );

  const pickSupportedMp4Mime = useCallback((preferred?: string) => {
    const candidates: string[] = [];
    if (preferred) candidates.push(preferred);
    candidates.push('video/mp4; codecs="avc1.42E01E, mp4a.40.2"');
    candidates.push('video/mp4; codecs="avc1.4D401E, mp4a.40.2"');
    candidates.push('video/mp4; codecs="avc1.64001F, mp4a.40.2"');
    candidates.push('video/mp4; codecs="avc1.42E01E"');
    candidates.push("video/mp4");

    for (const c of candidates) {
      try { if (MediaSource.isTypeSupported(c)) return c; } catch { /* ignore */ }
    }
    return "";
  }, []);

  const ingestMp4StreamBytes = useCallback(
    (chunk: Uint8Array) => {
      const merged = concatU8(mseBufRef.current, chunk);
      const { boxes, rest } = splitMp4Boxes(merged);
      mseBufRef.current = rest;

      if (boxes.length === 0) return;

      for (const box of boxes) {
        if (!mseInitDoneRef.current) {
          console.log("[fastsend] mp4 head box", box.type, box.data.byteLength);
          mseInitAccRef.current = concatU8(mseInitAccRef.current, box.data);
          if (box.type === "moov") mseSawMoovRef.current = true;

          if (box.type === "moof") {
            if (!mseSawMoovRef.current) {
              setStatusState("error", "播放器初始化失败（缺少 moov）");
              setShowReconnect(true);
              setStreaming(false);
              return;
            }
            mseQueueRef.current.push(mseInitAccRef.current);
            mseInitAccRef.current = new Uint8Array(0);
            mseInitDoneRef.current = true;
            msePendingMoofRef.current = box.data;
          }
          continue;
        }

        if (box.type === "moof") {
          if (msePendingMoofRef.current.byteLength > 0) {
            mseQueueRef.current.push(msePendingMoofRef.current);
          }
          msePendingMoofRef.current = box.data;
          continue;
        }

        if (msePendingMoofRef.current.byteLength > 0) {
          msePendingMoofRef.current = concatU8(msePendingMoofRef.current, box.data);
        } else {
          mseQueueRef.current.push(box.data);
        }
      }

      if (msePendingMoofRef.current.byteLength >= 512 * 1024) {
        mseQueueRef.current.push(msePendingMoofRef.current);
        msePendingMoofRef.current = new Uint8Array(0);
      }
    },
    [setStatusState, setShowReconnect],
  );

  const startMse = useCallback(() => {
    if (mediaSourceRef.current) return;
    if (!("MediaSource" in window)) {
      setStatusState("error", "当前浏览器不支持在线播放");
      setShowReconnect(true);
      return;
    }

    streamModeRef.current = "mse-fmp4";
    setStreaming(true);
    mseQueueRef.current = [];
    mseReadyRef.current = false;

    const ms = new MediaSource();
    mediaSourceRef.current = ms;
    const url = URL.createObjectURL(ms);
    if (mseUrlRef.current) {
      try { URL.revokeObjectURL(mseUrlRef.current); } catch { /* ignore */ }
    }
    mseUrlRef.current = url;
    setMseUrl(url);

    ms.addEventListener("sourceopen", () => {
      console.log("[fastsend] sourceopen, desiredMime:", desiredMimeRef.current);
      try {
        if (streamDurationRef.current > 0) {
          ms.duration = streamDurationRef.current;
        }
        if (!desiredMimeRef.current) {
          console.log("[fastsend] sourceopen: waiting for stream-meta before creating SourceBuffer");
          return;
        }
        const mime = pickSupportedMp4Mime(desiredMimeRef.current);
        if (!mime) {
          setStatusState("error", "浏览器不支持该视频编码（建议下载播放）");
          setShowReconnect(true);
          setStreaming(false);
          return;
        }
        if (!ensureSourceBuffer(ms, mime)) {
          setStatusState("error", `浏览器不支持该视频编码：${mime}`);
          setShowReconnect(true);
          setStreaming(false);
          return;
        }
      } catch (e) {
        console.error("[fastsend] sourceopen", e);
        setStatusState("error", "播放器初始化失败");
        setShowReconnect(true);
      }
    });
  }, [ensureSourceBuffer, pickSupportedMp4Mime, setStatusState, setShowReconnect]);

  const handleStreamMeta = useCallback(
    (m: {
      mime?: string;
      codecs?: string;
      duration?: number;
      binaryMode?: string;
      seeked?: boolean;
    }) => {
      console.log("[fastsend] stream-meta received:", m);
      if (m.duration && typeof m.duration === "number") {
        streamDurationRef.current = m.duration;
        setStreamDuration(m.duration);
      }
      if (m.seeked) {
        seekingRef.current = false;
        mseQueueRef.current = [];
        mseBufRef.current = new Uint8Array(0);
        mseInitDoneRef.current = false;
        mseInitAccRef.current = new Uint8Array(0);
        msePendingMoofRef.current = new Uint8Array(0);
        mseSawMoovRef.current = false;
        streamEndedRef.current = false;
      }
      if (m.mime && typeof m.mime === "string") {
        desiredMimeRef.current = m.mime;
      }
      streamBinaryModeRef.current =
        m.binaryMode === "init-segment-v1" ? "init-segment-v1" : "raw-mp4";
      const ms = mediaSourceRef.current;
      if (ms && ms.readyState === "open") {
        try {
          if (streamDurationRef.current > 0) {
            ms.duration = streamDurationRef.current;
          }
          const picked = pickSupportedMp4Mime(desiredMimeRef.current);
          console.log("[fastsend] stream-meta: picked mime:", picked, "from desired:", desiredMimeRef.current);
          if (!picked) {
            setStatusState("error", "浏览器不支持该视频编码（建议下载播放）");
            setShowReconnect(true);
            setStreaming(false);
            return;
          }
          if (!ensureSourceBuffer(ms, picked)) {
            setStatusState("error", `浏览器不支持该视频编码：${picked}`);
            setShowReconnect(true);
            setStreaming(false);
          }
        } catch (e) {
          console.error("[fastsend] stream-meta ensureSourceBuffer error:", e);
        }
      }
    },
    [ensureSourceBuffer, pickSupportedMp4Mime, setStatusState, setShowReconnect],
  );

  const handleStreamBinary = useCallback(
    (buf: ArrayBuffer) => {
      const u8 = new Uint8Array(buf);
      if (streamBinaryModeRef.current === "init-segment-v1") {
        if (u8.byteLength >= 2) {
          const kind = u8[0];
          const payload = u8.subarray(1);
          if (kind === 0 || kind === 1) {
            if (kind === 0) {
              console.log("[fastsend] init bytes", payload.byteLength);
            } else {
              console.log("[fastsend] seg bytes", payload.byteLength);
            }
            mseQueueRef.current.push(payload);
          }
        }
      } else {
        ingestMp4StreamBytes(u8);
      }
      pumpMse();
    },
    [ingestMp4StreamBytes, pumpMse],
  );

  const handleStreamDone = useCallback(() => {
    console.log("[fastsend] stream-done received, queue:", mseQueueRef.current.length, "initDone:", mseInitDoneRef.current);
    try {
      if (msePendingMoofRef.current.byteLength > 0) {
        mseQueueRef.current.push(msePendingMoofRef.current);
        msePendingMoofRef.current = new Uint8Array(0);
        pumpMse();
      }
    } catch { /* ignore */ }
    streamEndedRef.current = true;
    pumpMse();
  }, [pumpMse]);

  const handleStreamSeeked = useCallback(() => {
    seekingRef.current = false;
    mseQueueRef.current = [];
    mseBufRef.current = new Uint8Array(0);
    mseInitDoneRef.current = false;
    mseInitAccRef.current = new Uint8Array(0);
    msePendingMoofRef.current = new Uint8Array(0);
    mseSawMoovRef.current = false;
    streamEndedRef.current = false;
    const sb = sourceBufferRef.current;
    if (sb) {
      try {
        if (sb.updating) sb.abort();
        sb.abort();
        sb.remove(0, Infinity);
      } catch { /* ignore */ }
    }
  }, []);

  const sendSeek = useCallback(
    (targetTime: number) => {
      if (seekingRef.current) return;
      seekingRef.current = true;
      streamEndedRef.current = false;
      sendJson({ type: "stream-seek", targetTime });
    },
    [sendJson],
  );

  const setStreamProgress = useCallback((_bytes: number) => {
    // Intentional no-op: progress is managed by the orchestrator
  }, []);

  const resetStream = useCallback(() => {
    setStreaming(false);
    if (mseUrlRef.current) {
      try { URL.revokeObjectURL(mseUrlRef.current); } catch { /* ignore */ }
    }
    mseUrlRef.current = "";
    setMseUrl("");

    streamModeRef.current = "none";
    streamEndedRef.current = false;
    mseQueueRef.current = [];
    mseBufRef.current = new Uint8Array(0);
    mseInitDoneRef.current = false;
    mseInitAccRef.current = new Uint8Array(0);
    msePendingMoofRef.current = new Uint8Array(0);
    mseSawMoovRef.current = false;
    mseReadyRef.current = false;
    sourceBufferRef.current = null;
    mediaSourceRef.current = null;
    desiredMimeRef.current = "";
    streamBinaryModeRef.current = "raw-mp4";
    streamDurationRef.current = 0;
    setStreamDuration(0);
    seekingRef.current = false;
  }, []);

  return {
    mseUrl,
    streaming,
    streamDuration,
    streamModeRef,
    startMse,
    handleStreamMeta,
    handleStreamBinary,
    handleStreamDone,
    handleStreamSeeked,
    sendSeek,
    resetStream,
    pumpMse,
    setStreamProgress,
  };
}
