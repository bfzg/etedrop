/**
 * 分享页 WebRTC 调试：在地址栏加 `?p2pDebug=1` 后刷新，或控制台执行
 * `sessionStorage.setItem('FASTSEND_P2P_DEBUG','1')` 再刷新。
 * 控制台过滤 `[fastsend:p2p]`。
 */

const STORAGE_KEY = "FASTSEND_P2P_DEBUG";
const QUERY_KEY = "p2pDebug";

export function isP2pDebugEnabled(): boolean {
  if (typeof window === "undefined") return false;
  try {
    if (new URLSearchParams(window.location.search).get(QUERY_KEY) === "1") {
      return true;
    }
    return sessionStorage.getItem(STORAGE_KEY) === "1";
  } catch {
    return false;
  }
}

export function p2pLog(...args: unknown[]): void {
  if (!isP2pDebugEnabled()) return;
  // eslint-disable-next-line no-console
  console.log("[fastsend:p2p]", ...args);
}

/** 从 SDP candidate 字符串里粗分 typ（host / srflx / relay / prflx） */
export function summarizeIceCandidate(candidate: string): string {
  const parts = candidate.trim().split(/\s+/);
  const i = parts.indexOf("typ");
  const typ = i >= 0 && parts[i + 1] ? parts[i + 1] : "?";
  const proto = parts[0] === "candidate" && parts[1] ? parts[1] : "";
  return `${typ}${proto ? `/${proto}` : ""}`;
}

const prevTransportSampleByPc = new WeakMap<
  RTCPeerConnection,
  { atMs: number; bytesReceived: number; bytesSent: number }
>();

const iceSummaryLoggedForPc = new WeakSet<RTCPeerConnection>();

/** 仅在首次成功连接时打印一次选中链路与候选类型（避免 interval 重复刷 local-candidate） */
function logIceSummaryOnce(pc: RTCPeerConnection, stats: RTCStatsReport): void {
  if (iceSummaryLoggedForPc.has(pc)) return;

  const byId = new Map<string, unknown>();
  stats.forEach((r) => {
    byId.set(r.id, r);
  });

  type PairReport = {
    localCandidateId?: string;
    remoteCandidateId?: string;
    state?: string;
  };
  let pair: PairReport | undefined;
  for (const r of stats.values()) {
    if (r.type === "candidate-pair" && (r as { state?: string }).state === "succeeded") {
      pair = r as PairReport;
      break;
    }
  }
  const localId = pair?.localCandidateId;
  const remoteId = pair?.remoteCandidateId;
  if (!localId || !remoteId || pair == null) {
    return;
  }

  const loc = byId.get(localId) as
    | { candidateType?: string; address?: string; protocol?: string }
    | undefined;
  const rem = byId.get(remoteId) as
    | { candidateType?: string; address?: string; protocol?: string }
    | undefined;

  iceSummaryLoggedForPc.add(pc);
  p2pLog("ICE 选中路径（仅打印一次）", {
    pairState: pair.state,
    local: loc
      ? {
          type: loc.candidateType,
          address: loc.address || "(hidden)",
          protocol: loc.protocol,
        }
      : null,
    remote: rem
      ? {
          type: rem.candidateType,
          address: rem.address || "(hidden)",
          protocol: rem.protocol,
        }
      : null,
    hint:
      rem?.candidateType === "relay" || loc?.candidateType === "relay"
        ? "当前为 TURN 中继，吞吐常低于直连"
        : "非 relay 时路径一般正常；若仍慢，多为应用层 ack/写入或 SCTP 窗口，而非 STUN",
  });
}

/**
 * 周期性只打 **transport** 增量与估算 Mbps，避免每次把全部 candidate 再刷一遍。
 */
export async function logWebRtcTransportSnapshot(
  pc: RTCPeerConnection,
  label: string,
): Promise<void> {
  if (!isP2pDebugEnabled()) return;
  try {
    const stats = await pc.getStats();

    logIceSummaryOnce(pc, stats);

    type TransportReport = {
      bytesReceived?: number;
      bytesSent?: number;
      dtlsState?: string;
    };
    let transport: TransportReport | undefined;
    for (const r of stats.values()) {
      if (r.type === "transport") {
        transport = r as TransportReport;
        break;
      }
    }
    if (transport == null || typeof transport.bytesReceived !== "number") {
      p2pLog(`[stats:${label}] no transport stats yet`);
      return;
    }

    const rx: number = transport.bytesReceived;
    const tx: number = transport.bytesSent ?? 0;
    const now = typeof performance !== "undefined" ? performance.now() : Date.now();
    const prev = prevTransportSampleByPc.get(pc);

    if (prev) {
      const dtSec = (now - prev.atMs) / 1000;
      const drx = rx - prev.bytesReceived;
      const dtx = tx - prev.bytesSent;
      const rxMbps = dtSec > 0 ? ((drx * 8) / dtSec / 1e6).toFixed(2) : "0";
      p2pLog(`[stats:${label}] transport Δ`, {
        intervalSec: Number(dtSec.toFixed(2)),
        rxDeltaKB: Math.round(drx / 1024),
        txDeltaKB: Math.round(dtx / 1024),
        rxMbpsApprox: rxMbps,
        cumulativeRxMB: (rx / (1024 * 1024)).toFixed(2),
        dtlsState: transport.dtlsState,
      });
    } else {
      p2pLog(`[stats:${label}] transport baseline`, {
        bytesReceived: rx,
        bytesSent: tx,
        dtlsState: transport.dtlsState,
      });
    }

    prevTransportSampleByPc.set(pc, {
      atMs: now,
      bytesReceived: rx,
      bytesSent: tx,
    });
  } catch (e) {
    p2pLog(`[stats:${label}] getStats failed`, e);
  }
}
