import { useCallback, useRef, useState } from "react";
import type { StatusKind } from "./useSignaling";
import { concatU8, splitMp4Boxes } from "../utils/mp4Utils";

export type StreamMode = "none" | "mse-fmp4";
export type StreamBinaryMode = "raw-mp4" | "init-segment-v1";

const EVICT_KEEP_BEHIND_S = 10;
const EVICT_ROUTINE_AHEAD_S = 20;
const MAX_BUFFER_AHEAD_S = 60;
/** 播放头未越过此秒数时，不按「缓冲超前于 currentTime」做限流，避免 t=0 时把整段已缓冲算成超前而 pause 且永远无法 resume */
const BUFFER_AHEAD_GATE_PLAYHEAD_S = 0.5;
const FLOW_PAUSE_QUEUE_BYTES = 8 * 1024 * 1024;
const FLOW_RESUME_QUEUE_BYTES = 2 * 1024 * 1024;
const MSE_QUEUE_MAX_BYTES = 64 * 1024 * 1024;

export interface StreamPlayerApi {
  mseUrl: string;
  streaming: boolean;
  streamDuration: number;
  startMse: () => void;
  setPlaybackTime: (t: number) => void;
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
  handleStreamSeeked: (actualTime?: number) => void;
  sendSeek: (targetTime: number) => void;
  resetStream: () => void;
  streamModeRef: React.RefObject<StreamMode>;
  streamingActiveRef: React.RefObject<boolean>;
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
  const seekTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingSeekTimeRef = useRef<number | null>(null);
  const playbackTimeRef = useRef<number>(0);

  const mseQueueBytesRef = useRef(0);
  const quotaRetryCountRef = useRef(0);
  const streamPausedRef = useRef(false);
  const streamingActiveRef = useRef(false);
  streamingActiveRef.current = streaming;

  /** Send stream-pause or stream-resume to the Flutter sender based on queue depth
   *  and SourceBuffer ahead distance. */
  const updateFlowControl = useCallback(() => {
    const qBytes = mseQueueBytesRef.current;
    const sb = sourceBufferRef.current;
    const t = playbackTimeRef.current;
    let bufferAheadFull = false;
    if (sb && Number.isFinite(t) && t >= 0) {
      const b = sb.buffered;
      if (b.length > 0) {
        const ahead = b.end(b.length - 1) - t;
        bufferAheadFull =
          t >= BUFFER_AHEAD_GATE_PLAYHEAD_S && ahead > MAX_BUFFER_AHEAD_S;
      }
    }

    if (!streamPausedRef.current && (qBytes > FLOW_PAUSE_QUEUE_BYTES || bufferAheadFull)) {
      streamPausedRef.current = true;
      sendJson({ type: "stream-pause" });
    } else if (streamPausedRef.current && qBytes < FLOW_RESUME_QUEUE_BYTES && !bufferAheadFull) {
      streamPausedRef.current = false;
      sendJson({ type: "stream-resume" });
    }
  }, [sendJson]);

  /** Try to remove already-played data from the SourceBuffer.
   *  `force`: skip the "enough buffered ahead" check (used on QuotaExceededError).
   *  Returns true if a remove operation was started (sb.updating becomes true). */
  const evictSourceBuffer = useCallback((force: boolean): boolean => {
    const sb = sourceBufferRef.current;
    if (!sb || sb.updating) return false;
    if (!mseReadyRef.current) return false;
    const ms = mediaSourceRef.current;
    if (!ms || ms.readyState !== "open") return false;

    const b = sb.buffered;
    if (!b || b.length === 0) return false;

    const t = playbackTimeRef.current;
    if (!Number.isFinite(t) || t <= 0) return false;

    const start = b.start(0);
    const end = b.end(b.length - 1);
    if (!Number.isFinite(start) || !Number.isFinite(end)) return false;

    if (!force) {
      const ahead = end - t;
      if (!Number.isFinite(ahead) || ahead < EVICT_ROUTINE_AHEAD_S) return false;
    }

    const removeEnd = t - EVICT_KEEP_BEHIND_S;
    if (removeEnd <= start + 1) return false;

    try {
      sb.remove(start, removeEnd);
      return true;
    } catch (e) {
      console.warn("[fastsend] mse evict failed", e);
      return false;
    }
  }, []);

  const pumpMse = useCallback(() => {
    const sb = sourceBufferRef.current;
    if (!sb) return;
    if (!mseReadyRef.current) return;
    const ms = mediaSourceRef.current;
    if (!ms || ms.readyState !== "open") return;
    if (sb.updating) return;

    // Routine eviction: reclaim already-played data.
    if (evictSourceBuffer(false)) return; // remove started → updateend will call pumpMse again

    // Buffer-ahead limit: don't stuff more into SourceBuffer if we're already
    // far enough ahead of the playback position. Data stays in the JS queue
    // and will be appended as playback advances (driven by setPlaybackTime).
    const t = playbackTimeRef.current;
    const b = sb.buffered;
    if (b.length > 0) {
      const bufferedEnd = b.end(b.length - 1);
      const ahead = bufferedEnd - t;
      if (
        t >= BUFFER_AHEAD_GATE_PLAYHEAD_S &&
        ahead > MAX_BUFFER_AHEAD_S
      ) {
        updateFlowControl();
        return;
      }
    }

    // Apply timestampOffset after seek (before any new data is appended).
    if (pendingSeekTimeRef.current !== null) {
      const offset = pendingSeekTimeRef.current;
      pendingSeekTimeRef.current = null;
      try {
        sb.timestampOffset = offset;
        console.log("[fastsend] set timestampOffset =", offset);
      } catch (e) {
        console.warn("[fastsend] failed to set timestampOffset", e);
      }
      if (sb.updating) return;
    }

    const q = mseQueueRef.current;
    if (q.length === 0) {
      if (streamEndedRef.current) {
        try { ms.endOfStream(); } catch { /* ignore */ }
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
    for (const it of items) mseQueueBytesRef.current -= it.byteLength;
    if (mseQueueBytesRef.current < 0) mseQueueBytesRef.current = 0;
    try {
      const merged = new Uint8Array(totalSize);
      let off = 0;
      for (const it of items) {
        merged.set(it, off);
        off += it.byteLength;
      }
      sb.appendBuffer(merged);
      quotaRetryCountRef.current = 0;
      updateFlowControl();
    } catch (e) {
      if (e instanceof DOMException && e.name === "QuotaExceededError") {
        for (const it of items) mseQueueBytesRef.current += it.byteLength;
        q.unshift(...items);

        quotaRetryCountRef.current++;
        if (quotaRetryCountRef.current > 3) {
          console.error("[fastsend] QuotaExceededError persists after eviction retries");
          quotaRetryCountRef.current = 0;
          return;
        }
        console.warn(
          "[fastsend] QuotaExceededError, forcing eviction (attempt",
          quotaRetryCountRef.current + ")",
          "currentTime:", playbackTimeRef.current,
        );
        evictSourceBuffer(true);
      } else {
        console.error(
          "[fastsend] mse append error", e,
          "batchItems:", items.length,
          "batchSize:", totalSize,
          "readyState:", ms.readyState,
        );
      }
    }
  }, [evictSourceBuffer, updateFlowControl, onStreamEnd]);

  const setPlaybackTime = useCallback((t: number) => {
    if (!Number.isFinite(t) || t < 0) return;
    playbackTimeRef.current = t;
    updateFlowControl();
    pumpMse();
  }, [updateFlowControl, pumpMse]);

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
            mseQueueBytesRef.current += mseInitAccRef.current.byteLength;
            mseInitAccRef.current = new Uint8Array(0);
            mseInitDoneRef.current = true;
            msePendingMoofRef.current = box.data;
          }
          continue;
        }

        if (box.type === "moof") {
          if (msePendingMoofRef.current.byteLength > 0) {
            mseQueueRef.current.push(msePendingMoofRef.current);
            mseQueueBytesRef.current += msePendingMoofRef.current.byteLength;
          }
          msePendingMoofRef.current = box.data;
          continue;
        }

        if (msePendingMoofRef.current.byteLength > 0) {
          msePendingMoofRef.current = concatU8(msePendingMoofRef.current, box.data);
        } else {
          mseQueueRef.current.push(box.data);
          mseQueueBytesRef.current += box.data.byteLength;
        }
      }

      if (msePendingMoofRef.current.byteLength >= 512 * 1024) {
        mseQueueRef.current.push(msePendingMoofRef.current);
        mseQueueBytesRef.current += msePendingMoofRef.current.byteLength;
        msePendingMoofRef.current = new Uint8Array(0);
      }

      if (mseQueueBytesRef.current > MSE_QUEUE_MAX_BYTES) {
        console.error(
          "[fastsend] mse queue overflow",
          mseQueueBytesRef.current,
          "bytes; stopping stream",
        );
        setStatusState("error", "播放器缓冲过大（可能网络/性能不足），请重试或改用下载");
        setShowReconnect(true);
        setStreaming(false);
        streamEndedRef.current = false;
        mseQueueRef.current = [];
        mseQueueBytesRef.current = 0;
        return;
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
          if (kind === 0) {
            mseInitDoneRef.current = true;
            mseQueueRef.current.push(payload);
            mseQueueBytesRef.current += payload.byteLength;
          } else if (kind === 1) {
            if (!mseInitDoneRef.current) return; // drop stale data from old pipeline
            mseQueueRef.current.push(payload);
            mseQueueBytesRef.current += payload.byteLength;
          }
        }
      } else {
        ingestMp4StreamBytes(u8);
      }
      updateFlowControl();
      pumpMse();
    },
    [ingestMp4StreamBytes, updateFlowControl, pumpMse],
  );

  const handleStreamDone = useCallback(() => {
    console.log("[fastsend] stream-done received, queue:", mseQueueRef.current.length, "initDone:", mseInitDoneRef.current);
    try {
      if (msePendingMoofRef.current.byteLength > 0) {
        mseQueueRef.current.push(msePendingMoofRef.current);
        mseQueueBytesRef.current += msePendingMoofRef.current.byteLength;
        msePendingMoofRef.current = new Uint8Array(0);
        pumpMse();
      }
    } catch { /* ignore */ }
    streamEndedRef.current = true;
    pumpMse();
  }, [pumpMse]);

  const handleStreamSeeked = useCallback((actualTime?: number) => {
    seekingRef.current = false;
    streamPausedRef.current = false;
    mseQueueRef.current = [];
    mseQueueBytesRef.current = 0;
    mseBufRef.current = new Uint8Array(0);
    mseInitDoneRef.current = false;
    mseInitAccRef.current = new Uint8Array(0);
    msePendingMoofRef.current = new Uint8Array(0);
    mseSawMoovRef.current = false;
    streamEndedRef.current = false;
    pendingSeekTimeRef.current = actualTime ?? null;
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
      streamEndedRef.current = false;
      // Debounce: only send the seek after the user stops dragging for 500ms.
      // This prevents dozens of ffmpeg start/kill cycles from rapid seeking events.
      if (seekTimerRef.current) clearTimeout(seekTimerRef.current);
      seekTimerRef.current = setTimeout(() => {
        seekTimerRef.current = null;
        seekingRef.current = true;
        sendJson({ type: "stream-seek", targetTime });
      }, 500);
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
    streamPausedRef.current = false;
    if (seekTimerRef.current) { clearTimeout(seekTimerRef.current); seekTimerRef.current = null; }
    mseQueueRef.current = [];
    mseQueueBytesRef.current = 0;
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
    pendingSeekTimeRef.current = null;
  }, []);

  return {
    mseUrl,
    streaming,
    streamDuration,
    streamModeRef,
    streamingActiveRef,
    startMse,
    setPlaybackTime,
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
