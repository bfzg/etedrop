/**
 * 发布信息：线上以 `static/public/version.json` 为准（可只改 JSON 部署）；
 * 缺省或 fetch 失败时使用 FALLBACK_RELEASE。
 *
 * 分平台版本（可选）：`windowsVersion` / `macVersion` / `linuxVersion` / `iosVersion` /
 * `androidVersion`；省略时回退到 `latestVersion`。下载链接仍用各 `*DownloadUrl`。
 *
 * - `releaseNotes`：客户端内「当前版本」更新摘要（Flutter 等仍依赖此字段）。
 * - `changelog`：网站下载页多版本历史；每项 `{ version, notes: { zh, en, ja, ko, es } }`，新在前。
 *   若省略 `changelog` 或为空，网站端会用 `latestVersion` + `releaseNotes` 合成一条展示。
 */
/** 下载页「更新日志」一条版本记录；`notes` 与 `releaseNotes` 相同的多语言结构 */
export type ReleaseChangelogEntry = {
  version: string;
  notes: Record<string, string[]>;
};

export type ReleaseManifest = {
  /** 兼容旧清单：未写分平台版本时，各平台回退到此字段 */
  latestVersion: string;
  windowsVersion: string;
  macVersion: string;
  linuxVersion: string;
  iosVersion: string;
  androidVersion: string;
  windowsDownloadUrl: string;
  macDownloadUrl: string;
  linuxDownloadUrl: string;
  iosDownloadUrl: string;
  androidDownloadUrl: string;
  forceUpdate: boolean;
  releasePageUrl: string;
  releaseNotes: Record<string, string[]>;
  /** 多版本更新历史（新在前）；缺省时由 merge 用 latestVersion + releaseNotes 合成一条 */
  changelog: ReleaseChangelogEntry[];
};

/** 与 `static/public/version.json` 结构一致，便于一处对照填写 */
export const FALLBACK_RELEASE: ReleaseManifest = {
  latestVersion: "0.0.0",
  windowsVersion: "0.0.0",
  macVersion: "0.0.0",
  linuxVersion: "0.0.0",
  iosVersion: "0.0.0",
  androidVersion: "0.0.0",
  windowsDownloadUrl: "/downloads/EteDrop-Windows-x64.exe",
  macDownloadUrl: "/downloads/EteDrop-macOS.dmg",
  linuxDownloadUrl: "",
  iosDownloadUrl: "",
  androidDownloadUrl: "",
  forceUpdate: false,
  releasePageUrl: "",
  releaseNotes: {
    zh: [],
    en: [],
    ja: [],
    ko: [],
    es: [],
  },
  changelog: [],
};

export const VERSION_JSON_PUBLIC_PATH = "/public/version.json";

export type ClientDesktopPlatform = "windows" | "macos" | "linux" | "unknown";

/**
 * 浏览器内检测桌面端系统；移动端返回 unknown（首页按钮走下载页）。
 */
type NavigatorWithUAData = Navigator & {
  userAgentData?: {
    platform?: string;
    mobile?: boolean;
  };
};

export function getClientDownloadPlatform(): ClientDesktopPlatform {
  if (typeof navigator === "undefined") {
    return "unknown";
  }

  const uad = (navigator as NavigatorWithUAData).userAgentData;
  if (uad?.mobile) {
    return "unknown";
  }
  if (typeof uad?.platform === "string") {
    const p = uad.platform.toLowerCase();
    if (p.includes("win")) {
      return "windows";
    }
    if (p.includes("mac")) {
      return "macos";
    }
    if (p.includes("linux")) {
      return "linux";
    }
  }

  const ua = navigator.userAgent.toLowerCase();
  const platform = (navigator.platform || "").toLowerCase();

  if (/iphone|ipad|ipod|android/i.test(navigator.userAgent)) {
    return "unknown";
  }
  // iPadOS 桌面版 Safari 可能扮成 Mac，触屏设备排除
  if (platform.includes("mac") && navigator.maxTouchPoints > 1) {
    return "unknown";
  }

  if (platform.includes("win") || ua.includes("windows")) {
    return "windows";
  }
  if (platform.includes("mac") || ua.includes("mac os")) {
    return "macos";
  }
  if (platform.includes("linux") || ua.includes("linux") || ua.includes("x11")) {
    return "linux";
  }
  return "unknown";
}
