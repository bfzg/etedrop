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
  const [showReconnect, setShowReconnect] = useState(false);
  const [resumeHintBytes, setResumeHintBytes] = useState(0);
  const [playUrl, setPlayUrl] = useState<string>("");

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
  const statusKindRef = useRef<StatusKind>("pending");

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
  }, [closeOpfsWriter]);

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
            }
          } catch {
            /* ignore */
          }
        } else {
          const buf = ev.data as ArrayBuffer;
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
    [shareCode, setStatusState, finishDownload, deviceId, closeOpfsWriter],
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
  }) => {
    const dc = dcRef.current;
    if (!dc || dc.readyState !== "open") return;
    downloadIntentRef.current = opts?.intent ?? "download";
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
  }, [deviceId, shareCode]);

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
    showReconnect,
    resumeHintBytes,
    playUrl,
    sendVerify,
    sendDownloadStart,
    reconnect,
  };
}
