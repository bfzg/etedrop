/**
 * WebRTC ICE：STUN 仅用于发现公网地址，不参与传数据；条目过多会拖慢 ICE 收集。
 *
 * 顺序：大陆常见出口 / 低延迟优先，其次 Cloudflare、Google 等（公网互通场景）。
 * 公开大列表可参考：
 * - https://gist.github.com/mondain/b0ec1cf5f60ae726202e
 * - https://github.com/heiher/natmap/issues/18
 *
 * 跨网打洞失败时需自建 **TURN**（中继），仅靠 STUN 无法替代。
 */
const pubStunUrlsOrdered: string[] = [
  "stun:stun.qq.com:3478",
  "stun:stun.miwifi.com:3478",
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

export const pubStunList = pubStunUrlsOrdered.map((u) =>
  u.replace(/^stun:/, ""),
);

export const pubTurnList: RTCIceServer[] = [];

export const pubIceServers: RTCIceServer[] = [
  {
    urls: pubStunUrlsOrdered,
  },
  ...pubTurnList,
];
