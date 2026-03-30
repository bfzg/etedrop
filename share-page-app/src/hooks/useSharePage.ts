import { useCallback, useEffect, useRef, useState } from "react";
import type { DataChannelMessage } from "../types";
import {
  clearPartialFile,
  clearSessionMeta,
  ensureMetaMatchesOrClear,
  getOpfsPartialSize,
  hasOpfs,
  OpfsChunkWriter,
  parseOffsetPrefixedChunk,
  readSessionMeta,
} from "../utils/shareDownloadStorage";

type StatusKind = "pending" | "online" | "error";

type BinaryMode = "legacy" | "prefixed-opfs" | "prefixed-memory";

type DownloadIntent = "download" | "play";
type StreamMode = "none" | "mse-fmp4";
type StreamBinaryMode = "raw-mp4" | "init-segment-v1";

export function useSharePage(deviceId: string, shareCode: string) {
  const [status, setStatus] = useState<{ kind: StatusKind; text: string }>({
    kind: "pending",
    text: "正在连接设备…",
  });
  const [showStatusBar, setShowStatusBar] = useState(true);
  const [fileInfo, setFileInfo] = useState<{
    fileName: string;
    fileSize: number;
    hasPassword: boolean;
  } | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [passwordError, setPasswordError] = useState("");
  const [verifyLoading, setVerifyLoading] = useState(false);
  const [showDownloadBtn, setShowDownloadBtn] = useState(false);
  const [showProgress, setShowProgress] = useState(false);
  const [progress, setProgress] = useState({ received: 0, total: 0 });
  const [showDone, setShowDone] = useState(false);
  const [doneKind, setDoneKind] = useState<"" | "download" | "stream">("");
  const [showReconnect, setShowReconnect] = useState(false);
  const [resumeHintBytes, setResumeHintBytes] = useState(0);
  const [playUrl, setPlayUrl] = useState<string>("");
  const [mseUrl, setMseUrl] = useState<string>("");
  const [streaming, setStreaming] = useState(false);

  const wsRef = useRef<WebSocket | null>(null);
  const pcRef = useRef<RTCPeerConnection | null>(null);
  const dcRef = useRef<RTCDataChannel | null>(null);
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
  const statusKindRef = useRef<StatusKind>("pending");
  const streamDurationRef = useRef<number>(0);
  const seekingRef = useRef(false);

  const setStatusState = useCallback((kind: StatusKind, text: string) => {
    statusKindRef.current = kind;
    setStatus({ kind, text });
    setShowStatusBar(true);
  }, []);

  const closeOpfsWriter = useCallback(async () => {
    const w = opfsWriterRef.current;
    opfsWriterRef.current = null;
    if (w) {
      try {
        await w.close();
      } catch {
        /* ignore */
      }
    }
  }, []);

  const reset = useCallback(() => {
    void closeOpfsWriter();
    writeChainRef.current = Promise.resolve();
    opfsGateRef.current = Promise.resolve();
    setFileInfo(null);
    fileInfoRef.current = null;
    setShowPassword(false);
    setPasswordError("");
    setShowDownloadBtn(false);
    setShowProgress(false);
    setProgress({ received: 0, total: 0 });
    setShowDone(false);
    setDoneKind("");
    setStreaming(false);
    setShowReconnect(false);
    setResumeHintBytes(0);
    chunksRef.current = [];
    memoryDataChunksRef.current = [];
    totalBytesRef.current = 0;
    expectedNextOffsetRef.current = 0;
    binaryModeRef.current = "legacy";
    downloadCompletedRef.current = false;
    downloadIntentRef.current = "download";

    if (playUrlRef.current) {
      try {
        URL.revokeObjectURL(playUrlRef.current);
      } catch {
        /* ignore */
      }
    }
    playUrlRef.current = "";
    setPlayUrl("");

    if (mseUrlRef.current) {
      try {
        URL.revokeObjectURL(mseUrlRef.current);
      } catch {
        /* ignore */
      }
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
    seekingRef.current = false;
  }, [closeOpfsWriter]);

  const concatU8 = (a: Uint8Array, b: Uint8Array) => {
    if (a.byteLength === 0) return b;
    if (b.byteLength === 0) return a;
    const out = new Uint8Array(a.byteLength + b.byteLength);
    out.set(a, 0);
    out.set(b, a.byteLength);
    return out;
  };

  const splitMp4Boxes = (buf: Uint8Array) => {
    // 返回：可追加的完整 box 序列（按原顺序），以及剩余不完整尾部。
    const out: Array<{ type: string; data: Uint8Array }> = [];
    let off = 0;
    while (buf.byteLength - off >= 8) {
      const dv = new DataView(
        buf.buffer,
        buf.byteOffset + off,
        buf.byteLength - off,
      );
      const size32 = dv.getUint32(0, false);
      const type = String.fromCharCode(
        dv.getUint8(4),
        dv.getUint8(5),
        dv.getUint8(6),
        dv.getUint8(7),
      );
      let boxSize: number | null = null;
      let headerSize = 8;

      if (size32 === 0) {
        // 到文件末尾（对流不友好），这里停止解析，等待更多数据或结束。
        break;
      } else if (size32 === 1) {
        if (buf.byteLength - off < 16) break;
        const size64 = dv.getBigUint64(8, false);
        if (size64 > BigInt(Number.MAX_SAFE_INTEGER)) break;
        boxSize = Number(size64);
        headerSize = 16;
      } else {
        boxSize = size32;
      }

      if (!boxSize || boxSize < headerSize) break;
      if (buf.byteLength - off < boxSize) break;

      out.push({ type, data: buf.subarray(off, off + boxSize) });
      off += boxSize;
    }
    return { boxes: out, rest: buf.subarray(off) };
  };

  const ingestMp4StreamBytes = useCallback(
    (chunk: Uint8Array) => {
      // 将任意分块的 MP4 字节流拼接并按 box 边界切分，然后严格按「init segment」和「media segment」追加：
      // - init：ftyp + moov（合并为一次 append）
      // - media：按 moof(+紧随的 mdat/其他) 作为一次 append
      const merged = concatU8(mseBufRef.current, chunk);
      const { boxes, rest } = splitMp4Boxes(merged);
      mseBufRef.current = rest;

      if (boxes.length === 0) return;

      for (const box of boxes) {
        if (!mseInitDoneRef.current) {
          // init 阶段：在遇到第一个 moof 之前，把所有 box 都拼进 init（包含 free 等），但必须看到 moov。
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
            // init 必须先 append，再开始第一段 media（以 moof 起头）
            mseQueueRef.current.push(mseInitAccRef.current);
            mseInitAccRef.current = new Uint8Array(0);
            mseInitDoneRef.current = true;

            // start first media segment with this moof
            msePendingMoofRef.current = box.data;
          }
          continue;
        }

        // media segments: start at moof, include following boxes (mdat etc) until next moof
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
          // 理论上 media 段应从 moof 开始；遇到 stray box 先丢进队列（尽量不阻塞）
          mseQueueRef.current.push(box.data);
        }
      }

      // 控制队列增长：当 pending segment 足够大时先入队，减少内存峰值
      if (msePendingMoofRef.current.byteLength >= 512 * 1024) {
        mseQueueRef.current.push(msePendingMoofRef.current);
        msePendingMoofRef.current = new Uint8Array(0);
      }
    },
    [setStatusState],
  );

  const pumpMse = useCallback(() => {
    const sb = sourceBufferRef.current;
    if (!sb) return;
    if (!mseReadyRef.current) return;
    if (sb.updating) return;
    const q = mseQueueRef.current;
    if (q.length === 0) {
      if (streamEndedRef.current) {
        try {
          mediaSourceRef.current?.endOfStream();
        } catch {
          /* ignore */
        }
        setShowProgress(false);
        setShowDone(true);
        setDoneKind("stream");
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
        "[fastsend] mse append error",
        e,
        "batchItems:", items.length,
        "batchSize:", totalSize,
        "readyState:", mediaSourceRef.current?.readyState,
      );
    }
  }, []);

  const ensureSourceBuffer = useCallback(
    (ms: MediaSource, mime: string) => {
      if (sourceBufferRef.current) {
        console.log("[fastsend] ensureSourceBuffer: already exists");
        return true;
      }
      console.log("[fastsend] ensureSourceBuffer: creating with mime:", mime);
      if (!MediaSource.isTypeSupported(mime)) {
        console.warn("[fastsend] ensureSourceBuffer: mime NOT supported:", mime);
        return false;
      }
      const sb = ms.addSourceBuffer(mime);
      sourceBufferRef.current = sb;
      sb.mode = "segments";
      sb.addEventListener("updateend", () => {
        pumpMse();
      });
      sb.addEventListener("error", (e) => {
        console.error("[fastsend] SourceBuffer error event:", e);
      });
      mseReadyRef.current = true;
      pumpMse();
      return true;
    },
    [pumpMse],
  );

  const pickSupportedMp4Mime = useCallback(
    (preferred?: string) => {
      const candidates: string[] = [];
      if (preferred) candidates.push(preferred);
      // H.264 fallback (safe default; HEVC only when desktop explicitly provides it as preferred)
      candidates.push('video/mp4; codecs="avc1.42E01E, mp4a.40.2"');
      candidates.push('video/mp4; codecs="avc1.4D401E, mp4a.40.2"');
      candidates.push('video/mp4; codecs="avc1.64001F, mp4a.40.2"');
      candidates.push('video/mp4; codecs="avc1.42E01E"');
      candidates.push('video/mp4');

      for (const c of candidates) {
        try {
          if (MediaSource.isTypeSupported(c)) return c;
        } catch {
          // ignore
        }
      }
      return "";
    },
    [],
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
      try {
        URL.revokeObjectURL(mseUrlRef.current);
      } catch {
        /* ignore */
      }
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
  }, [ensureSourceBuffer, pickSupportedMp4Mime, setStatusState]);

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
          try {
            URL.revokeObjectURL(playUrlRef.current);
          } catch {
            /* ignore */
          }
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

  const startRTC = useCallback(
    (ws: WebSocket) => {
      if (dcRef.current) {
        try {
          dcRef.current.close();
        } catch {
          /* ignore */
        }
        dcRef.current = null;
      }
      if (pcRef.current) {
        try {
          pcRef.current.close();
        } catch {
          /* ignore */
        }
        pcRef.current = null;
      }

      void closeOpfsWriter();
      writeChainRef.current = Promise.resolve();
      opfsGateRef.current = Promise.resolve();
      chunksRef.current = [];
      memoryDataChunksRef.current = [];
      binaryModeRef.current = "legacy";
      downloadCompletedRef.current = false;

      const pc = new RTCPeerConnection({
        iceServers: [{ urls: "stun:stun.l.google.com:19302" }],
      });
      pcRef.current = pc;

      const dc = pc.createDataChannel("share", { ordered: true });
      dc.binaryType = "arraybuffer";
      dcRef.current = dc;

      dc.onopen = () => {
        setStatusState("online", "P2P 已连接，获取文件信息…");
        dc.send(JSON.stringify({ type: "share-request", shareCode }));
      };

      dc.onmessage = (ev) => {
        if (typeof ev.data === "string") {
          try {
            const m = JSON.parse(ev.data) as DataChannelMessage;
            switch (m.type) {
              case "share-info":
                void ensureMetaMatchesOrClear(
                  deviceId,
                  shareCode,
                  m.fileName,
                  m.fileSize,
                );
                fileInfoRef.current = {
                  fileName: m.fileName,
                  fileSize: m.fileSize,
                  hasPassword: !!m.hasPassword,
                };
                setFileInfo(fileInfoRef.current);
                setShowStatusBar(false);
                if (hasOpfs()) {
                  void (async () => {
                    const meta = readSessionMeta(deviceId, shareCode);
                    const fi = fileInfoRef.current;
                    if (
                      !fi ||
                      !meta ||
                      meta.fileName !== fi.fileName ||
                      meta.fileSize !== fi.fileSize
                    ) {
                      setResumeHintBytes(0);
                      return;
                    }
                    const n = await getOpfsPartialSize(deviceId, shareCode);
                    setResumeHintBytes(
                      n > 0 && n < fi.fileSize ? n : 0,
                    );
                  })();
                } else {
                  setResumeHintBytes(0);
                }
                if (m.hasPassword) {
                  setShowPassword(true);
                  setShowDownloadBtn(false);
                } else {
                  setShowPassword(false);
                  setShowDownloadBtn(true);
                }
                break;
              case "error":
                setStatusState("error", m.message || "未知错误");
                setShowReconnect(true);
                break;
              case "verify-result":
                if (m.success) {
                  setShowPassword(false);
                  setPasswordError("");
                  setShowDownloadBtn(true);
                } else {
                  setPasswordError(m.error || "密码错误");
                  setVerifyLoading(false);
                }
                break;
              case "file-meta": {
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

                setShowDownloadBtn(false);
                setShowProgress(true);
                break;
              }
              case "file-done":
                downloadCompletedRef.current = true;
                void finishDownload();
                break;
              case "stream-meta": {
                console.log("[fastsend] stream-meta received:", m);
                if (m.duration && typeof m.duration === "number") {
                  streamDurationRef.current = m.duration;
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
                  m.binaryMode === "init-segment-v1"
                    ? "init-segment-v1"
                    : "raw-mp4";
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
                      break;
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
                break;
              }
              case "stream-seeked": {
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
                  } catch {
                    /* ignore */
                  }
                }
                break;
              }
              case "stream-done":
                console.log("[fastsend] stream-done received, queue:", mseQueueRef.current.length, "initDone:", mseInitDoneRef.current);
                downloadCompletedRef.current = true;
                try {
                  // flush pending media segment
                  if (msePendingMoofRef.current.byteLength > 0) {
                    mseQueueRef.current.push(msePendingMoofRef.current);
                    msePendingMoofRef.current = new Uint8Array(0);
                    pumpMse();
                  }
                } catch {
                  /* ignore */
                }
                streamEndedRef.current = true;
                pumpMse();
                break;
            }
          } catch {
            /* ignore */
          }
        } else {
          const buf = ev.data as ArrayBuffer;
          if (streamModeRef.current === "mse-fmp4") {
            const u8 = new Uint8Array(buf);
            if (streamBinaryModeRef.current === "init-segment-v1") {
              if (u8.byteLength >= 2) {
                const kind = u8[0];
                const payload = u8.subarray(1);
                // kind=0 init, kind=1 segment
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
            // 进度信息在流模式下不精确，先用“已接收字节数”展示。
            setProgress((p) => ({
              received: p.received + buf.byteLength,
              total: p.total || totalBytesRef.current || 1,
            }));
            return;
          }
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
                console.warn(
                  "[fastsend] chunk offset mismatch",
                  offset,
                  expectedNextOffsetRef.current,
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
              } else {
                memoryDataChunksRef.current.push(data);
              }
              expectedNextOffsetRef.current += data.byteLength;
              const t = totalBytesRef.current;
              setProgress({
                received: expectedNextOffsetRef.current,
                total: t,
              });
            })
            .catch((e) => {
              console.error("[fastsend] write chunk", e);
            });
        }
      };

      dc.onclose = () => {
        if (!downloadCompletedRef.current) {
          setStatusState("error", "P2P 连接已断开（可重新连接后续传）");
          setShowReconnect(true);
        }
      };

      pc.onicecandidate = (ev) => {
        if (ev.candidate && ws.readyState === 1) {
          ws.send(
            JSON.stringify({
              type: "ice-candidate",
              data: {
                candidate: ev.candidate.candidate,
                sdpMid: ev.candidate.sdpMid,
                sdpMLineIndex: ev.candidate.sdpMLineIndex,
              },
            }),
          );
        }
      };

      pc.oniceconnectionstatechange = () => {
        if (pc.iceConnectionState === "failed") {
          setStatusState("error", "P2P 连接失败，请重试");
          setShowReconnect(true);
        }
      };

      pc.createOffer()
        .then((offer) => pc.setLocalDescription(offer))
        .then(() => {
          ws.send(
            JSON.stringify({
              type: "offer",
              data: {
                sdp: pc.localDescription!.sdp,
                type: pc.localDescription!.type,
              },
            }),
          );
        })
        .catch(() => {
          setStatusState("error", "创建连接失败");
          setShowReconnect(true);
        });
    },
    [
      shareCode,
      setStatusState,
      finishDownload,
      deviceId,
      closeOpfsWriter,
      ingestMp4StreamBytes,
      pumpMse,
      ensureSourceBuffer,
      pickSupportedMp4Mime,
    ],
  );

  const connect = useCallback(() => {
    reset();
    setStatusState("pending", "正在连接设备…");

    const proto = location.protocol === "https:" ? "wss:" : "ws:";
    const ws = new WebSocket(proto + "//" + location.host + "/api/share");
    wsRef.current = ws;

    ws.onopen = () => {
      ws.send(JSON.stringify({ type: "connect", deviceId }));
    };

    ws.onmessage = (ev) => {
      try {
        const m = JSON.parse(ev.data as string);
        switch (m.type) {
          case "device-online":
            setStatusState("online", "设备在线，正在建立 P2P 连接…");
            startRTC(ws);
            break;
          case "answer":
            if (pcRef.current && m.data) {
              pcRef.current.setRemoteDescription(
                new RTCSessionDescription(m.data),
              );
            }
            break;
          case "ice-candidate":
            if (pcRef.current && m.data) {
              pcRef.current
                .addIceCandidate(new RTCIceCandidate(m.data))
                .catch(() => {});
            }
            break;
          case "err":
            setStatusState(
              "error",
              m.code === "OFFLINE"
                ? "分享者设备离线，请稍后再试"
                : m.msg || "连接异常",
            );
            setShowReconnect(true);
            break;
        }
      } catch {
        setStatusState("error", "消息解析失败");
        setShowReconnect(true);
      }
    };

    ws.onerror = () => {
      setStatusState("error", "网络连接失败");
      setShowReconnect(true);
    };

    ws.onclose = () => {
      if (statusKindRef.current === "pending") {
        setStatusState("error", "连接已关闭");
        setShowReconnect(true);
      }
    };
  }, [deviceId, reset, setStatusState, startRTC]);

  useEffect(() => {
    connect();
    return () => {
      void closeOpfsWriter();
      if (dcRef.current) {
        try {
          dcRef.current.close();
        } catch {
          /* ignore */
        }
        dcRef.current = null;
      }
      if (pcRef.current) {
        try {
          pcRef.current.close();
        } catch {
          /* ignore */
        }
        pcRef.current = null;
      }
      if (wsRef.current) {
        try {
          wsRef.current.close();
        } catch {
          /* ignore */
        }
        wsRef.current = null;
      }
    };
  }, [connect, closeOpfsWriter]);

  const sendVerify = useCallback((password: string) => {
    const dc = dcRef.current;
    if (!dc || dc.readyState !== "open") return;
    setVerifyLoading(true);
    setPasswordError("");
    dc.send(JSON.stringify({ type: "share-verify", password }));
  }, []);

  const sendDownloadStart = useCallback(async (opts?: {
    intent?: DownloadIntent;
    remuxFmp4?: boolean;
    stream?: boolean;
  }) => {
    const dc = dcRef.current;
    if (!dc || dc.readyState !== "open") return;
    downloadIntentRef.current = opts?.intent ?? "download";

    if (opts?.stream) {
      startMse();
      dc.send(
        JSON.stringify({
          type: "stream-start",
          remuxFmp4: !!opts?.remuxFmp4,
        }),
      );
      setShowDownloadBtn(false);
      setShowProgress(true);
      return;
    }
    let resume = 0;
    const fi = fileInfoRef.current;
    if (fi && hasOpfs()) {
      const meta = readSessionMeta(deviceId, shareCode);
      if (
        meta &&
        meta.fileName === fi.fileName &&
        meta.fileSize === fi.fileSize
      ) {
        resume = await getOpfsPartialSize(deviceId, shareCode);
        if (resume > fi.fileSize) resume = fi.fileSize;
      }
    }
    dc.send(
      JSON.stringify({
        type: "download-start",
        resumeFrom: resume,
        remuxFmp4: !!opts?.remuxFmp4,
      }),
    );
  }, [deviceId, shareCode, startMse]);

  const sendSeek = useCallback((targetTime: number) => {
    const dc = dcRef.current;
    if (!dc || dc.readyState !== "open") return;
    if (seekingRef.current) return;
    seekingRef.current = true;
    streamEndedRef.current = false;
    dc.send(JSON.stringify({ type: "stream-seek", targetTime }));
  }, []);

  const reconnect = useCallback(() => {
    if (dcRef.current) {
      try {
        dcRef.current.close();
      } catch {
        /* ignore */
      }
      dcRef.current = null;
    }
    if (pcRef.current) {
      try {
        pcRef.current.close();
      } catch {
        /* ignore */
      }
      pcRef.current = null;
    }
    if (wsRef.current) {
      try {
        wsRef.current.close();
      } catch {
        /* ignore */
      }
      wsRef.current = null;
    }
    connect();
  }, [connect]);

  return {
    status,
    showStatusBar,
    fileInfo,
    showPassword,
    passwordError,
    verifyLoading,
    showDownloadBtn,
    showProgress,
    progress,
    showDone,
    doneKind,
    showReconnect,
    resumeHintBytes,
    playUrl,
    mseUrl,
    streaming,
    sendVerify,
    sendDownloadStart,
    sendSeek,
    reconnect,
  };
}
