export function isWeChat(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent || "";
  return /MicroMessenger/i.test(ua);
}

export function isIOS(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent || "";
  return /iPhone|iPad|iPod/i.test(ua);
}

export function isAndroid(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent || "";
  return /Android/i.test(ua);
}

export function isMobile(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent || "";
  return /Mobile|Android|iPhone|iPad|iPod/i.test(ua);
}

/** 桌面 / iOS 上的 Apple Safari（排除 Chrome、Edge、Firefox、Opera 等同样含 WebKit 字样的浏览器） */
export function isSafari(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent || "";
  if (!/Safari/i.test(ua)) return false;
  if (/Chrome|CriOS|Chromium|EdgA|EdgiOS|Edg\/|OPR|FxiOS|OPT\/|Brave/i.test(ua)) {
    return false;
  }
  return /AppleWebKit/i.test(ua);
}

