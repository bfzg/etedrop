import { useCallback, useEffect, useRef, useState } from "react";

export type StatusKind = "pending" | "online" | "error";

export type DcMessageHandler = (ev: MessageEvent) => void;

export function useSignaling(deviceId: string, shareCode: string) {
  const [status, setStatus] = useState<{ kind: StatusKind; text: string }>({
    kind: "pending",
    text: "正在连接设备…",
  });
  const [showStatusBar, setShowStatusBar] = useState(true);
  const [showReconnect, setShowReconnect] = useState(false);

  const wsRef = useRef<WebSocket | null>(null);
  const pcRef = useRef<RTCPeerConnection | null>(null);
  const dcRef = useRef<RTCDataChannel | null>(null);
  const statusKindRef = useRef<StatusKind>("pending");
  const dcMessageHandlerRef = useRef<DcMessageHandler | null>(null);

  const setStatusState = useCallback((kind: StatusKind, text: string) => {
    statusKindRef.current = kind;
    setStatus({ kind, text });
    setShowStatusBar(true);
  }, []);

  const setDcMessageHandler = useCallback((handler: DcMessageHandler) => {
    dcMessageHandlerRef.current = handler;
  }, []);

  const startRTC = useCallback(
    (ws: WebSocket) => {
      if (dcRef.current) {
        try { dcRef.current.close(); } catch { /* ignore */ }
        dcRef.current = null;
      }
      if (pcRef.current) {
        try { pcRef.current.close(); } catch { /* ignore */ }
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
        dcMessageHandlerRef.current?.(ev);
      };

      dc.onclose = () => {
        dcMessageHandlerRef.current?.(
          new MessageEvent("close", { data: "__dc_close__" }),
        );
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
    [shareCode, setStatusState],
  );

  const connect = useCallback(() => {
    setStatusState("pending", "正在连接设备…");
    setShowReconnect(false);

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
  }, [deviceId, setStatusState, startRTC]);

  const cleanup = useCallback(() => {
    if (dcRef.current) {
      try { dcRef.current.close(); } catch { /* ignore */ }
      dcRef.current = null;
    }
    if (pcRef.current) {
      try { pcRef.current.close(); } catch { /* ignore */ }
      pcRef.current = null;
    }
    if (wsRef.current) {
      try { wsRef.current.close(); } catch { /* ignore */ }
      wsRef.current = null;
    }
  }, []);

  const reconnect = useCallback(() => {
    cleanup();
    connect();
  }, [cleanup, connect]);

  useEffect(() => {
    connect();
    return cleanup;
  }, [connect, cleanup]);

  const sendJson = useCallback((data: unknown) => {
    const dc = dcRef.current;
    if (!dc || dc.readyState !== "open") return;
    dc.send(JSON.stringify(data));
  }, []);

  return {
    dc: dcRef,
    status,
    showStatusBar,
    setShowStatusBar,
    showReconnect,
    setShowReconnect,
    reconnect,
    setStatusState,
    sendJson,
    setDcMessageHandler,
  };
}
