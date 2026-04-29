import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { pubIceServersForHost } from "../constants/constants";
import {
  isP2pDebugEnabled,
  logWebRtcTransportSnapshot,
  p2pLog,
  summarizeIceCandidate,
} from "../utils/p2pDebug";

export type StatusKind = "pending" | "online" | "error";

export type DcMessageHandler = (ev: MessageEvent) => void;

/** 浏览器侧 WebSocket 保活（代理/网关空闲断连） */
const BROWSER_WS_HEARTBEAT_MS = 25_000;
/** 等待 DataChannel open */
const P2P_READY_TIMEOUT_MS = 45_000;

export function useSignaling(deviceId: string, shareCode: string) {
  const { t } = useTranslation();
  const [status, setStatus] = useState<{ kind: StatusKind; text: string }>({
    kind: "pending",
    text: t("status.connecting"),
  });
  const [showStatusBar, setShowStatusBar] = useState(true);
  const [showReconnect, setShowReconnect] = useState(false);

  const wsRef = useRef<WebSocket | null>(null);
  const pcRef = useRef<RTCPeerConnection | null>(null);
  const dcRef = useRef<RTCDataChannel | null>(null);
  const statusKindRef = useRef<StatusKind>("pending");
  const dcMessageHandlerRef = useRef<DcMessageHandler | null>(null);
  const heartbeatTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const pendingDcOpenRef = useRef<{
    resolve: () => void;
    reject: (e: Error) => void;
  } | null>(null);
  const p2pStatsTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  /**
   * 我们「主动」关闭 DC/PC 时（cleanup、reconnect、startRTC 中的 closePcDcOnly），
   * 浏览器仍会触发 dc.onclose。这里用一个标记跳过对外 `__dc_close__` 通知，
   * 否则 useSharePage 会把这种「主动关闭」当成对端断线，再去触发一轮整网重连，
   * 形成「断开 -> 重连 -> 断开」死循环。
   */
  const suppressNextDcCloseRef = useRef(false);

  const setStatusState = useCallback((kind: StatusKind, text: string) => {
    statusKindRef.current = kind;
    setStatus({ kind, text });
    setShowStatusBar(true);
  }, []);

  const setDcMessageHandler = useCallback((handler: DcMessageHandler) => {
    dcMessageHandlerRef.current = handler;
  }, []);

  const stopBrowserHeartbeat = useCallback(() => {
    if (heartbeatTimerRef.current != null) {
      window.clearInterval(heartbeatTimerRef.current);
      heartbeatTimerRef.current = null;
    }
  }, []);

  const startBrowserHeartbeat = useCallback(
    (ws: WebSocket) => {
      stopBrowserHeartbeat();
      heartbeatTimerRef.current = window.setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
          try {
            ws.send(JSON.stringify({ type: "heartbeat" }));
          } catch {
            /* ignore */
          }
        }
      }, BROWSER_WS_HEARTBEAT_MS);
    },
    [stopBrowserHeartbeat],
  );

  const rejectPendingDcOpen = useCallback((reason: string) => {
    const p = pendingDcOpenRef.current;
    if (p) {
      pendingDcOpenRef.current = null;
      p.reject(new Error(reason));
    }
  }, []);

  const resolvePendingDcOpen = useCallback(() => {
    const p = pendingDcOpenRef.current;
    if (p) {
      pendingDcOpenRef.current = null;
      p.resolve();
    }
  }, []);

  const closePcDcOnly = useCallback(() => {
    if (p2pStatsTimerRef.current != null) {
      window.clearInterval(p2pStatsTimerRef.current);
      p2pStatsTimerRef.current = null;
    }
    stopBrowserHeartbeat();
    if (dcRef.current || pcRef.current) {
      // 「主动关闭」模式：本次 dc.onclose 不要再向上通知 useSharePage，
      // 否则会触发它的「流式播放断线 → 900ms 后整网 reconnect」逻辑。
      suppressNextDcCloseRef.current = true;
    }
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
  }, [stopBrowserHeartbeat]);

  const armPendingDcOpen = useCallback((): Promise<void> => {
    return new Promise((resolve, reject) => {
      const timer = window.setTimeout(() => {
        if (pendingDcOpenRef.current?.reject) {
          pendingDcOpenRef.current.reject(new Error("P2P open timeout"));
          pendingDcOpenRef.current = null;
        }
      }, P2P_READY_TIMEOUT_MS);
      pendingDcOpenRef.current = {
        resolve: () => {
          window.clearTimeout(timer);
          pendingDcOpenRef.current = null;
          resolve();
        },
        reject: (e: Error) => {
          window.clearTimeout(timer);
          pendingDcOpenRef.current = null;
          reject(e);
        },
      };
    });
  }, []);

  const startRTC = useCallback(
    (ws: WebSocket) => {
      closePcDcOnly();

      const iceServers = pubIceServersForHost(
        typeof location !== "undefined" ? location.hostname : "",
      );

      const pc = new RTCPeerConnection({
        iceServers,
      });
      pcRef.current = pc;

      const urlCount = Array.isArray(iceServers[0]?.urls)
        ? (iceServers[0]!.urls as string[]).length
        : 0;
      p2pLog("RTCPeerConnection created", {
        iceServerUrlCount: urlCount,
        hint: "add ?p2pDebug=1 to URL for verbose logs",
      });

      pc.onicegatheringstatechange = () => {
        p2pLog("iceGatheringState", pc.iceGatheringState);
      };

      pc.onconnectionstatechange = () => {
        p2pLog("pc.connectionState", pc.connectionState);
        // 故意 closePcDcOnly 再 startRTC 时也会经过 closed，不能据此 reject
        if (pc.connectionState === "failed") {
          setStatusState("error", t("status.p2pFailed"));
          setShowReconnect(true);
          rejectPendingDcOpen("pc failed");
        }
      };

      const dc = pc.createDataChannel("share", { ordered: true });
      dc.binaryType = "arraybuffer";
      dcRef.current = dc;

      dc.onopen = () => {
        // 新连接已建好：之前留下的「主动关闭抑制位」已无意义，清掉，
        // 之后任何意外的 dc.onclose 都应正常上报。
        suppressNextDcCloseRef.current = false;
        setStatusState("online", t("status.p2pConnected"));
        setShowReconnect(false);
        p2pLog("DataChannel open", {
          label: dc.label,
          ordered: dc.ordered,
          bufferedAmount: dc.bufferedAmount,
        });
        void logWebRtcTransportSnapshot(pc, "dc-open");
        if (isP2pDebugEnabled()) {
          if (p2pStatsTimerRef.current != null) {
            window.clearInterval(p2pStatsTimerRef.current);
          }
          p2pStatsTimerRef.current = window.setInterval(() => {
            void logWebRtcTransportSnapshot(pc, "interval");
          }, 4000);
        }
        dc.send(JSON.stringify({ type: "share-request", shareCode }));
        startBrowserHeartbeat(ws);
        resolvePendingDcOpen();
      };

      dc.onmessage = (ev) => {
        dcMessageHandlerRef.current?.(ev);
      };

      dc.onerror = (ev) => {
        console.error("[fastsend] DataChannel error", {
          readyState: dc.readyState,
          bufferedAmount: dc.bufferedAmount,
          event: ev,
          pcConnectionState: pc.connectionState,
          iceConnectionState: pc.iceConnectionState,
        });
        p2pLog("DataChannel error", {
          readyState: dc.readyState,
          bufferedAmount: dc.bufferedAmount,
          pcConnectionState: pc.connectionState,
          iceConnectionState: pc.iceConnectionState,
        });
        void logWebRtcTransportSnapshot(pc, "dc-error");
      };

      dc.onclose = () => {
        const suppressed = suppressNextDcCloseRef.current;
        suppressNextDcCloseRef.current = false;
        console.warn("[fastsend] DataChannel close", {
          suppressed,
          readyState: dc.readyState,
          bufferedAmount: dc.bufferedAmount,
          pcConnectionState: pc.connectionState,
          iceConnectionState: pc.iceConnectionState,
        });
        p2pLog("DataChannel close", {
          suppressed,
          readyState: dc.readyState,
          bufferedAmount: dc.bufferedAmount,
          pcConnectionState: pc.connectionState,
          iceConnectionState: pc.iceConnectionState,
        });
        void logWebRtcTransportSnapshot(pc, "dc-close");
        // 主动关闭（cleanup / 重新 startRTC）不再向上通知，避免 useSharePage
        // 把这种内部状态切换误判成「对端掉线 → 整网重连」。
        if (suppressed) return;
        dcMessageHandlerRef.current?.(
          new MessageEvent("close", { data: "__dc_close__" }),
        );
      };

      pc.onicecandidate = (ev) => {
        if (ev.candidate?.candidate) {
          p2pLog(
            "local ICE → signaling",
            summarizeIceCandidate(ev.candidate.candidate),
          );
        } else {
          p2pLog("local ICE gathering complete (end-of-candidates)");
        }
        if (ev.candidate && ws.readyState === WebSocket.OPEN) {
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
        p2pLog("iceConnectionState", pc.iceConnectionState);
        if (pc.iceConnectionState === "failed") {
          setStatusState("error", t("status.p2pFailed"));
          setShowReconnect(true);
          rejectPendingDcOpen("ice failed");
        }
      };

      pc
        .createOffer()
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
          setStatusState("error", t("status.createOfferFailed"));
          setShowReconnect(true);
          rejectPendingDcOpen("createOffer failed");
        });
    },
    [
      closePcDcOnly,
      rejectPendingDcOpen,
      resolvePendingDcOpen,
      setStatusState,
      shareCode,
      startBrowserHeartbeat,
      t,
    ],
  );

  const waitForDcConnecting = useCallback((): Promise<boolean> => {
    const dc = dcRef.current;
    if (!dc || dc.readyState !== "connecting") return Promise.resolve(false);
    return new Promise((resolve) => {
      const to = window.setTimeout(() => resolve(false), P2P_READY_TIMEOUT_MS);
      const done = (ok: boolean) => {
        window.clearTimeout(to);
        dc.removeEventListener("open", onOpen);
        dc.removeEventListener("close", onClose);
        resolve(ok);
      };
      const onOpen = () => done(true);
      const onClose = () => done(false);
      dc.addEventListener("open", onOpen, { once: true });
      dc.addEventListener("close", onClose, { once: true });
    });
  }, []);

  const isP2pUsable = useCallback((): boolean => {
    const dc = dcRef.current;
    const pc = pcRef.current;
    if (!dc || dc.readyState !== "open") return false;
    if (!pc) return false;
    const s = pc.connectionState;
    return s !== "closed" && s !== "failed";
  }, []);

  const cleanup = useCallback(() => {
    if (p2pStatsTimerRef.current != null) {
      window.clearInterval(p2pStatsTimerRef.current);
      p2pStatsTimerRef.current = null;
    }
    stopBrowserHeartbeat();
    if (dcRef.current || pcRef.current) {
      // 见 closePcDcOnly 注释：主动关闭场景。
      suppressNextDcCloseRef.current = true;
    }
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
  }, [stopBrowserHeartbeat]);

  const connect = useCallback(() => {
    setStatusState("pending", t("status.connecting"));
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
            setStatusState("online", t("status.deviceOnline"));
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
            rejectPendingDcOpen(m.msg as string);
            setStatusState(
              "error",
              m.code === "OFFLINE"
                ? t("status.sharerOffline")
                : (m.msg as string) || t("status.connectionError"),
            );
            setShowReconnect(true);
            break;
        }
      } catch {
        rejectPendingDcOpen("parse failed");
        setStatusState("error", t("status.parseFailed"));
        setShowReconnect(true);
      }
    };

    ws.onerror = () => {
      rejectPendingDcOpen("ws error");
      setStatusState("error", t("status.networkFailed"));
      setShowReconnect(true);
    };

    ws.onclose = () => {
      rejectPendingDcOpen("ws closed");
      if (statusKindRef.current === "pending") {
        setStatusState("error", t("status.connectionClosed"));
        setShowReconnect(true);
      }
    };
  }, [deviceId, rejectPendingDcOpen, setStatusState, startRTC, t]);

  const ensureP2PReady = useCallback(async (): Promise<void> => {
    if (isP2pUsable()) return;

    const d = dcRef.current;
    if (d?.readyState === "connecting") {
      const ok = await waitForDcConnecting();
      if (ok && isP2pUsable()) return;
    }

    setStatusState("pending", t("status.reestablishingP2p"));
    setShowReconnect(false);

    const p = armPendingDcOpen();

    try {
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        closePcDcOnly();
        startRTC(wsRef.current);
      } else {
        cleanup();
        connect();
      }
      await p;
    } catch {
      setStatusState("error", t("status.p2pFailed"));
      setShowReconnect(true);
      throw new Error("ensureP2PReady failed");
    }
  }, [
    armPendingDcOpen,
    cleanup,
    closePcDcOnly,
    connect,
    isP2pUsable,
    setStatusState,
    startRTC,
    t,
    waitForDcConnecting,
  ]);

  const reconnect = useCallback(() => {
    rejectPendingDcOpen("reconnect");
    cleanup();
    connect();
  }, [cleanup, connect, rejectPendingDcOpen]);

  /** connect/cleanup 随 i18n、回调引用变化而变体；挂载 effect 只应随 deviceId/shareCode 重连，否则会误拆 P2P */
  const connectRef = useRef(connect);
  const cleanupRef = useRef(cleanup);
  const rejectUnmountRef = useRef(rejectPendingDcOpen);

  useEffect(() => {
    connectRef.current = connect;
    cleanupRef.current = cleanup;
    rejectUnmountRef.current = rejectPendingDcOpen;
  });

  useEffect(() => {
    let cancelled = false;
    const tmr = window.setTimeout(() => {
      if (!cancelled) connectRef.current();
    }, 0);
    return () => {
      cancelled = true;
      window.clearTimeout(tmr);
      rejectUnmountRef.current("unmount");
      cleanupRef.current();
    };
  }, [deviceId, shareCode]);

  const sendJson = useCallback((data: unknown) => {
    const dc = dcRef.current;
    const isStreamDataAck =
      typeof data === "object" &&
      data !== null &&
      (data as { type?: string }).type === "stream-data-ack";
    if (!dc || dc.readyState !== "open") {
      if (isStreamDataAck) {
        console.warn("[fastsend] stream-data-ack not sent: dc missing or not open", {
          dcExists: !!dc,
          readyState: dc?.readyState,
          payload: data,
        });
      }
      return;
    }
    if (isStreamDataAck) {
      console.log("[fastsend] dc.send stream-data-ack", data);
    }
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
    ensureP2PReady,
  };
}
