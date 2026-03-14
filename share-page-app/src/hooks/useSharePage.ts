import { useCallback, useEffect, useRef, useState } from "react";
import type { DataChannelMessage } from "../types";

type StatusKind = "pending" | "online" | "error";

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

  const wsRef = useRef<WebSocket | null>(null);
  const pcRef = useRef<RTCPeerConnection | null>(null);
  const dcRef = useRef<RTCDataChannel | null>(null);
  const chunksRef = useRef<ArrayBuffer[]>([]);
  const totalBytesRef = useRef(0);
  const fileInfoRef = useRef<{
    fileName: string;
    fileSize: number;
    hasPassword: boolean;
  } | null>(null);

  const setStatusState = useCallback((kind: StatusKind, text: string) => {
    setStatus({ kind, text });
    setShowStatusBar(true);
  }, []);

  const reset = useCallback(() => {
    setFileInfo(null);
    fileInfoRef.current = null;
    setShowPassword(false);
    setPasswordError("");
    setShowDownloadBtn(false);
    setShowProgress(false);
    setProgress({ received: 0, total: 0 });
    setShowDone(false);
    setShowReconnect(false);
    chunksRef.current = [];
  }, []);

  const finishDownload = useCallback(() => {
    const chunks = chunksRef.current;
    const fi = fileInfoRef.current;
    if (chunks.length === 0) return;
    const blob = new Blob(chunks);
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = fi?.fileName ?? "download";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    setTimeout(() => URL.revokeObjectURL(url), 5000);
    chunksRef.current = [];
    setShowProgress(false);
    setShowDone(true);
  }, []);

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
      if (status.kind === "pending") {
        setStatusState("error", "连接已关闭");
        setShowReconnect(true);
      }
    };
  }, [deviceId, reset, setStatusState, status.kind]);

  const startRTC = useCallback(
    (ws: WebSocket) => {
      if (dcRef.current) {
        try {
          dcRef.current.close();
        } catch {}
        dcRef.current = null;
      }
      if (pcRef.current) {
        try {
          pcRef.current.close();
        } catch {}
        pcRef.current = null;
      }

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
                fileInfoRef.current = {
                  fileName: m.fileName,
                  fileSize: m.fileSize,
                  hasPassword: !!m.hasPassword,
                };
                setFileInfo(fileInfoRef.current);
                setShowStatusBar(false);
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
              case "file-meta":
                chunksRef.current = [];
                totalBytesRef.current = m.fileSize;
                setProgress({ received: 0, total: m.fileSize });
                setShowDownloadBtn(false);
                setShowProgress(true);
                break;
              case "file-done":
                finishDownload();
                break;
            }
          } catch {}
        } else {
          chunksRef.current.push(ev.data as ArrayBuffer);
          const total = totalBytesRef.current || 1;
          const received = chunksRef.current.reduce(
            (acc, c) => acc + c.byteLength,
            0,
          );
          setProgress((p) => ({ ...p, received, total }));
        }
      };

      dc.onclose = () => {
        if (!showDone) {
          setStatusState("error", "P2P 连接已断开");
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
    [shareCode, setStatusState, showDone, finishDownload],
  );

  useEffect(() => {
    connect();
    return () => {
      if (dcRef.current) {
        try {
          dcRef.current.close();
        } catch {}
        dcRef.current = null;
      }
      if (pcRef.current) {
        try {
          pcRef.current.close();
        } catch {}
        pcRef.current = null;
      }
      if (wsRef.current) {
        try {
          wsRef.current.close();
        } catch {}
        wsRef.current = null;
      }
    };
  }, [deviceId, shareCode]);

  const sendVerify = useCallback((password: string) => {
    const dc = dcRef.current;
    if (!dc || dc.readyState !== "open") return;
    setVerifyLoading(true);
    setPasswordError("");
    dc.send(JSON.stringify({ type: "share-verify", password }));
  }, []);

  const sendDownloadStart = useCallback(() => {
    const dc = dcRef.current;
    if (!dc || dc.readyState !== "open") return;
    dc.send(JSON.stringify({ type: "download-start" }));
  }, []);

  const reconnect = useCallback(() => {
    if (dcRef.current) {
      try {
        dcRef.current.close();
      } catch {}
      dcRef.current = null;
    }
    if (pcRef.current) {
      try {
        pcRef.current.close();
      } catch {}
      pcRef.current = null;
    }
    if (wsRef.current) {
      try {
        wsRef.current.close();
      } catch {}
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
    sendVerify,
    sendDownloadStart,
    reconnect,
  };
}
