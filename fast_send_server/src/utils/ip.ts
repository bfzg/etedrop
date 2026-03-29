import * as os from 'os';

/**
 * 获取非环回 IPv4 地址
 * @returns 非环回 IPv4 地址列表
 */
export function nonLoopbackIpv4Addresses(): string[] {
  const nets = os.networkInterfaces();
  const out: string[] = [];
  for (const addrs of Object.values(nets ?? {})) {
    if (!addrs) continue;
    for (const a of addrs) {
      const fam = a.family as string | number;
      const isV4 = fam === 'IPv4' || fam === 4;
      if (isV4 && !a.internal) {
        out.push(a.address);
      }
    }
  }
  return out;
}
