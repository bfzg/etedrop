import { useCallback, useRef, useState } from "react";
import type { StatusKind } from "./useSignaling";
import { concatU8, splitMp4Boxes } from "../utils/mp4Utils";

export type StreamMode = "none" | "mse-fmp4";
export type StreamBinaryMode = "raw-mp4" | "init-segment-v1" | "init-segment-v2";

/** 与 Flutter `_kStreamBinVersionV2` / `_kStreamBinHeaderV2Bytes` 一致 */
const STREAM_BIN_VER_V2 = 2;
const STREAM_BIN_HDR_V2 = 6;

function parseInitSegV2Frame(u8: Uint8Array): {
  kind: number;
  seq: number;
  payload: Uint8Array;
} | null {
  if (u8.byteLength < STREAM_BIN_HDR_V2 || u8[0] !== STREAM_BIN_VER_V2) return null;
  const kind = u8[1];
  const seq = new DataView(u8.buffer, u8.byteOffset + 2, 4).getUint32(0, false);
  return { kind, seq, payload: u8.subarray(STREAM_BIN_HDR_V2) };
}

const EVICT_KEEP_BEHIND_S = 10;
const EVICT_ROUTINE_AHEAD_S = 20;
const MAX_BUFFER_AHEAD_S = 120;
const FLOW_PAUSE_QUEUE_BYTES = 24 * 1024 * 1024;
const FLOW_RESUME_QUEUE_BYTES = 8 * 1024 * 1024;
const MSE_QUEUE_MAX_BYTES = 64 * 1024 * 1024;
const STREAM_SEEK_DEBOUNCE_MS = 120;
const HIGH_RES_4K_WIDTH = 3840;
const HIGH_RES_4K_HEIGHT = 2160;
const HIGH_RES_MAX_BUFFER_AHEAD_S = 20;
const HIGH_RES_FLOW_PAUSE_QUEUE_BYTES = 12 * 1024 * 1024;
const HIGH_RES_FLOW_RESUME_QUEUE_BYTES = 4 * 1024 * 1024;
const STREAM_DATA_ACK_WINDOW_BYTES = 2 * 1024 * 1024;

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
    width?: number;
    height?: number;
    binaryMode?: string;
    seeked?: boolean;
    resume?: boolean;
    actualTime?: number;
  }) => void;
  handleStreamBinary: (buf: ArrayBuffer) => void;
  handleStreamDone: () => void;
  handleStreamSeeked: (actualTime?: number) => void;
  sendSeek: (targetTime: number) => void;
  resetStream: () => void;
  /** 当前播放进度（秒）；DC 断开 → 自动续播时用作 sender 端 -ss 起点。
   *  返回 0 表示还没开始播或不可用，由调用方自行决定是否走整重置流程。 */
  getResumeTime: () => number;
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
  const maxBufferAheadSecRef = useRef(MAX_BUFFER_AHEAD_S);
  const flowPauseQueueBytesRef = useRef(FLOW_PAUSE_QUEUE_BYTES);
  const flowResumeQueueBytesRef = useRef(FLOW_RESUME_QUEUE_BYTES);
  const streamAckPendingBytesRef = useRef(0);
  /** 最近收到的二进制帧 wire seq（v2）；用于 stream-data-ack.upToSeq */
  const streamWireSeqRef = useRef(0);
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
        const bufferedStart = b.start(0);
        const bufferedEnd = b.end(b.length - 1);
        const ahead = bufferedEnd - t;
        // seek 后 remux 分片的时间轴可能从较大时间点开始（例如 396s），
        // 而 video.currentTime 还短暂停在 0~几秒。此时不能按 ahead 判满，
        // 否则会误发 stream-pause，sender 永久停在 gate，表现为“拖动后不播”。
        const timeAligned = t + 2 >= bufferedStart;
        // 含 t≈0：仍按「已缓冲时长 − currentTime」限流，否则开播会把整文件尽快 append，
        // Quota / 内存 / SCTP 背压导致只播一截或 P2P 断链（与 Flutter 是否全速推流叠加）。
        bufferAheadFull = timeAligned && ahead > maxBufferAheadSecRef.current;
      }
    }

    if (!streamPausedRef.current && (qBytes > flowPauseQueueBytesRef.current || bufferAheadFull)) {
      streamPausedRef.current = true;
      sendJson({ type: "stream-pause" });
    } else if (streamPausedRef.current && qBytes < flowResumeQueueBytesRef.current && !bufferAheadFull) {
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
      if (ahead > maxBufferAheadSecRef.current) {
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
    const maxBatch = 4 * 1024 * 1024;
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
      width?: number;
      height?: number;
      binaryMode?: string;
      seeked?: boolean;
      resume?: boolean;
      actualTime?: number;
    }) => {
      console.log("[fastsend] stream-meta received:", m);
      if (m.duration && typeof m.duration === "number") {
        streamDurationRef.current = m.duration;
        setStreamDuration(m.duration);
      }
      const width = typeof m.width === "number" ? m.width : undefined;
      const height = typeof m.height === "number" ? m.height : undefined;
      const isHighRes4k =
        (width != null && width >= HIGH_RES_4K_WIDTH) ||
        (height != null && height >= HIGH_RES_4K_HEIGHT);
      if (isHighRes4k) {
        maxBufferAheadSecRef.current = HIGH_RES_MAX_BUFFER_AHEAD_S;
        flowPauseQueueBytesRef.current = HIGH_RES_FLOW_PAUSE_QUEUE_BYTES;
        flowResumeQueueBytesRef.current = HIGH_RES_FLOW_RESUME_QUEUE_BYTES;
      } else {
        maxBufferAheadSecRef.current = MAX_BUFFER_AHEAD_S;
        flowPauseQueueBytesRef.current = FLOW_PAUSE_QUEUE_BYTES;
        flowResumeQueueBytesRef.current = FLOW_RESUME_QUEUE_BYTES;
      }
      console.log("[fastsend] stream profile", {
        width,
        height,
        highRes4k: isHighRes4k,
        maxBufferAheadSec: maxBufferAheadSecRef.current,
        pauseQueueBytes: flowPauseQueueBytesRef.current,
        resumeQueueBytes: flowResumeQueueBytesRef.current,
      });
      // 「断流续播」分支：DC 断开重连后 sender 收到带 resumeFrom 的 stream-start，
      // 回的 stream-meta 会带 resume:true。此时 SourceBuffer/MediaSource 是同一份，
      // 只需清掉旧的 mp4 box 解析状态 + SB.buffered，让新的 init+segment 重新装入。
      // transcode 路径 sender 会把 resumeFrom 作为 actualTime 回传 → 用它当
      // SB.timestampOffset，新数据会落在该时间点；remux 路径默认保留原始 PTS，
      // 不动 timestampOffset 即可自然接续。
      if (m.resume) {
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
        streamAckPendingBytesRef.current = 0;
        streamWireSeqRef.current = 0;
        pendingSeekTimeRef.current =
          typeof m.actualTime === "number" && Number.isFinite(m.actualTime)
            ? m.actualTime
            : null;
        const sb = sourceBufferRef.current;
        if (sb) {
          try {
            if (sb.updating) sb.abort();
            sb.abort();
            sb.remove(0, Infinity);
          } catch { /* ignore */ }
        }
      }
      if (m.mime && typeof m.mime === "string") {
        desiredMimeRef.current = m.mime;
      }
      if (m.binaryMode === "init-segment-v2") {
        streamBinaryModeRef.current = "init-segment-v2";
      } else if (m.binaryMode === "init-segment-v1") {
        streamBinaryModeRef.current = "init-segment-v1";
      } else {
        streamBinaryModeRef.current = "raw-mp4";
      }
      if (!m.resume) {
        streamAckPendingBytesRef.current = 0;
        streamWireSeqRef.current = 0;
      }
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
      const mode = streamBinaryModeRef.current;
      let ackWindowBytes = 0;

      const applyInitSegPayload = (kind: number, payload: Uint8Array): boolean => {
        if (kind === 0) {
          mseInitDoneRef.current = true;
          mseQueueRef.current.push(payload);
          mseQueueBytesRef.current += payload.byteLength;
          return true;
        }
        if (kind === 1) {
          if (!mseInitDoneRef.current) return false;
          mseQueueRef.current.push(payload);
          mseQueueBytesRef.current += payload.byteLength;
          ackWindowBytes = payload.byteLength;
          return true;
        }
        return false;
      };

      if (mode === "init-segment-v2") {
        const parsed = parseInitSegV2Frame(u8);
        if (!parsed) {
          console.warn("[fastsend] drop binary: expected init-segment-v2 frame");
          updateFlowControl();
          pumpMse();
          return;
        }
        streamWireSeqRef.current = parsed.seq >>> 0;
        if (!applyInitSegPayload(parsed.kind, parsed.payload)) {
          updateFlowControl();
          pumpMse();
          return;
        }
      } else if (mode === "init-segment-v1") {
        const parsed = parseInitSegV2Frame(u8);
        if (parsed) {
          streamWireSeqRef.current = parsed.seq >>> 0;
          if (!applyInitSegPayload(parsed.kind, parsed.payload)) {
            updateFlowControl();
            pumpMse();
            return;
          }
        } else if (u8.byteLength >= 2 && (u8[0] === 0 || u8[0] === 1)) {
          streamWireSeqRef.current = 0;
          const kind = u8[0];
          const payload = u8.subarray(1);
          if (!applyInitSegPayload(kind, payload)) {
            updateFlowControl();
            pumpMse();
            return;
          }
        }
      } else {
        ingestMp4StreamBytes(u8);
        ackWindowBytes = u8.byteLength;
      }

      if (ackWindowBytes > 0) {
        streamAckPendingBytesRef.current += ackWindowBytes;
        while (streamAckPendingBytesRef.current >= STREAM_DATA_ACK_WINDOW_BYTES) {
          const ackMsg: {
            type: "stream-data-ack";
            bytes: number;
            upToSeq?: number;
          } = {
            type: "stream-data-ack",
            bytes: STREAM_DATA_ACK_WINDOW_BYTES,
          };
          if (mode === "init-segment-v2") {
            ackMsg.upToSeq = streamWireSeqRef.current;
          } else if (mode === "init-segment-v1" && streamWireSeqRef.current > 0) {
            ackMsg.upToSeq = streamWireSeqRef.current;
          }
          sendJson(ackMsg);
          streamAckPendingBytesRef.current -= STREAM_DATA_ACK_WINDOW_BYTES;
        }
      }
      updateFlowControl();
      pumpMse();
    },
    [ingestMp4StreamBytes, updateFlowControl, pumpMse, sendJson],
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
    streamAckPendingBytesRef.current = 0;
    streamWireSeqRef.current = 0;
    if (typeof actualTime === "number" && Number.isFinite(actualTime) && actualTime >= 0) {
      playbackTimeRef.current = actualTime;
    }
    pendingSeekTimeRef.current = actualTime ?? null;
    if (streamPausedRef.current) {
      streamPausedRef.current = false;
      sendJson({ type: "stream-resume" });
    }
    const sb = sourceBufferRef.current;
    if (sb) {
      try {
        if (sb.updating) sb.abort();
        sb.abort();
        sb.remove(0, Infinity);
      } catch { /* ignore */ }
    }
  }, [sendJson]);

  const sendSeek = useCallback(
    (targetTime: number) => {
      streamEndedRef.current = false;
      if (Number.isFinite(targetTime) && targetTime >= 0) {
        // 提前把流控锚点移动到用户目标时间，避免 seek 期间按旧时间轴误判“ahead 过大”。
        playbackTimeRef.current = targetTime;
      }
      // Keep a short debounce to coalesce rapid drag events while still interrupting
      // the old stream quickly and restarting from the target position.
      if (seekTimerRef.current) clearTimeout(seekTimerRef.current);
      seekTimerRef.current = setTimeout(() => {
        seekTimerRef.current = null;
        seekingRef.current = true;
        sendJson({ type: "stream-seek", targetTime });
      }, STREAM_SEEK_DEBOUNCE_MS);
    },
    [sendJson],
  );

  const setStreamProgress = useCallback((_bytes: number) => {
    // Intentional no-op: progress is managed by the orchestrator
  }, []);

  /** 取当前续播起点：优先 video.currentTime，再退化到 SourceBuffer.buffered 末端。
   *  减一点 epsilon，避免 sender 端 ffmpeg `-ss` 落在帧边界后没有可输出关键帧。
   *  视频 duration 已知时按 (duration - 1) 截顶，避免 sender 误判为「越界」直接重头开始。 */
  const getResumeTime = useCallback((): number => {
    let t = playbackTimeRef.current;
    if (!Number.isFinite(t) || t < 0) t = 0;
    if (t === 0) {
      const sb = sourceBufferRef.current;
      if (sb) {
        try {
          const b = sb.buffered;
          if (b.length > 0) {
            const end = b.end(b.length - 1);
            if (Number.isFinite(end) && end > 0) t = end;
          }
        } catch { /* ignore */ }
      }
    }
    if (t <= 0) return 0;
    const dur = streamDurationRef.current;
    if (dur > 1 && t >= dur - 0.5) t = dur - 1;
    return Math.max(0, t - 0.3);
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
    maxBufferAheadSecRef.current = MAX_BUFFER_AHEAD_S;
    flowPauseQueueBytesRef.current = FLOW_PAUSE_QUEUE_BYTES;
    flowResumeQueueBytesRef.current = FLOW_RESUME_QUEUE_BYTES;
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
    streamAckPendingBytesRef.current = 0;
    streamWireSeqRef.current = 0;
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
    getResumeTime,
  };
}
