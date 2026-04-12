/** 主站营销域名（海外源）；在此展示「访问国内镜像」引导 */
export const GLOBAL_MARKETING_HOSTNAMES: readonly string[] = [
  "etedrop.com",
  "www.etedrop.com",
];

const CHINA_TIMEZONES: readonly string[] = [
  "Asia/Shanghai",
  "Asia/Chongqing",
  "Asia/Urumqi",
];

export function isGlobalMarketingHost(hostname: string): boolean {
  const h = hostname.toLowerCase();
  for (let i = 0; i < GLOBAL_MARKETING_HOSTNAMES.length; i += 1) {
    if (GLOBAL_MARKETING_HOSTNAMES[i] === h) {
      return true;
    }
  }
  return false;
}

/** 启发式：中国大陆时区或 zh-CN 语言（非精确地理） */
export function isLikelyMainlandChinaClient(): boolean {
  if (typeof Intl !== "undefined") {
    try {
      const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
      if (tz) {
        for (let i = 0; i < CHINA_TIMEZONES.length; i += 1) {
          if (CHINA_TIMEZONES[i] === tz) {
            return true;
          }
        }
      }
    } catch {
      /* ignore */
    }
  }
  if (typeof navigator === "undefined") {
    return false;
  }
  const lang = navigator.language.toLowerCase();
  if (lang === "zh-cn") {
    return true;
  }
  return lang.length > 7 && lang.slice(0, 7) === "zh-cn-";
}

export const CN_MIRROR_DISMISS_KEY = "etedrop.cnMirror.bannerDismissed";
