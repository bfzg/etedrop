export const pubStunList = [
  "stun.cloudflare.com:3478",
  "stun.qq.com:3478",
  "stun.miwifi.com:3478",
  "stun.l.google.com:19302",
  "stun1.l.google.com:19302",
  "stun2.l.google.com:19302",
  "stun3.l.google.com:19302",
  "stun4.l.google.com:19302",
];

export const pubTurnList: RTCIceServer[] = [];

export const pubIceServers: RTCIceServer[] = [
  {
    urls: pubStunList.map((i) => `stun:${i}`),
  },
  ...pubTurnList,
];

