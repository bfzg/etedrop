/**
 * WebRTC ICE：STUN 仅用于发现公网地址，不参与传数据；条目过多会拖慢 ICE 收集。
 *
 * 顺序与 Flutter [AppConstants.pubIceServersForRegion] 对齐：
 * - 大陆倾向：Bilibili 等优先（与选到 api-cn 或浏览器语言推断为大陆一致）
 * - 海外/全球：Google 系优先
 *
 * 公开大列表可参考：
 * - https://gist.github.com/mondain/b0ec1cf5f60ae726202e
 * - https://github.com/heiher/natmap/issues/18
 *
 * 跨网打洞失败时需自建 **TURN**（中继），仅靠 STUN 无法替代。
 */

const STUN_MAINLAND_FIRST: string[] = [
  "stun:stun.chat.bilibili.com:3478",
  "stun:stun.cloudflare.com:3478",
  "stun:stun.fbsbx.com:3478",
  "stun:stun.l.google.com:19302",
  "stun:stun1.l.google.com:19302",
  "stun:stun2.l.google.com:19302",
  "stun:stun3.l.google.com:19302",
  "stun:stun4.l.google.com:19302",
  "stun:stun.counterpath.net:3478",
  "stun:stun.stunprotocol.org:3478",
];

const STUN_GLOBAL_FIRST: string[] = [
  "stun:stun.l.google.com:19302",
  "stun:stun1.l.google.com:19302",
  "stun:stun2.l.google.com:19302",
  "stun:stun3.l.google.com:19302",
  "stun:stun4.l.google.com:19302",
  "stun:stun.cloudflare.com:3478",
  "stun:stun.fbsbx.com:3478",
  "stun:stun.chat.bilibili.com:3478",
  "stun:stun.counterpath.net:3478",
  "stun:stun.stunprotocol.org:3478",
];

export const pubTurnList: RTCIceServer[] = [];

/**
 * 与 Flutter `ServerEndpoints.resolve` 中 auto 规则对齐（简化版，基于页面域名 + `navigator.language`）。
 */
export function mainlandStunPreferred(hostname: string): boolean {
  const h = hostname.toLowerCase();
  if (h.includes("api-cn")) return true;

  if (typeof navigator === "undefined") return false;

  try {
    const loc = new Intl.Locale(navigator.language);
    if (loc.language !== "zh") return false;
    const r = loc.region;
    if (!r) return true;
    if (["TW", "HK", "MO"].includes(r)) return false;
    if (r === "CN") return true;
    return false;
  } catch {
    const raw = (navigator.language || "").toLowerCase();
    if (!raw.startsWith("zh")) return false;
    return !/-(tw|hk|mo)\b/i.test(raw);
  }
}

export function pubIceServersForHost(hostname: string): RTCIceServer[] {
  const urls = mainlandStunPreferred(hostname)
    ? STUN_MAINLAND_FIRST
    : STUN_GLOBAL_FIRST;
  return [{ urls: [...urls] }, ...pubTurnList];
}

/** 兼容旧代码：固定为「全球」顺序（Google 优先）。新逻辑请用 [pubIceServersForHost]。 */
export const pubIceServers: RTCIceServer[] = [
  { urls: [...STUN_GLOBAL_FIRST] },
  ...pubTurnList,
];

export const pubStunList = STUN_GLOBAL_FIRST.map((u) =>
  u.replace(/^stun:/, ""),
);
