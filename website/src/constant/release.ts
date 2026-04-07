/**
 * 发布信息：线上以 `static/public/version.json` 为准（可只改 JSON 部署）；
 * 缺省或 fetch 失败时使用 FALLBACK_RELEASE。
 */
export type ReleaseManifest = {
  latestVersion: string;
  windowsDownloadUrl: string;
  macDownloadUrl: string;
  forceUpdate: boolean;
  releasePageUrl: string;
  releaseNotes: Record<string, string[]>;
};

/** 与 `static/public/version.json` 结构一致，便于一处对照填写 */
export const FALLBACK_RELEASE: ReleaseManifest = {
  latestVersion: "0.0.0",
  windowsDownloadUrl: "/downloads/EteDrop-Windows-x64.exe",
  macDownloadUrl: "/downloads/EteDrop-macOS.dmg",
  forceUpdate: false,
  releasePageUrl: "",
  releaseNotes: {
    zh: [],
    en: [],
    ja: [],
    ko: [],
    es: [],
  },
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
