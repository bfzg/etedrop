import ExecutionEnvironment from "@docusaurus/ExecutionEnvironment";

const DEFAULT_LOCALE = "zh-Hans";

/** 与 fix-double-locale.js、docusaurus.config 的 i18n.locales 保持一致 */
const LOCALES = new Set(["zh-Hans", "en", "ja", "es", "ko"]);

const SKIP_AUTO_KEY = "etedrop.i18n.skipAuto";

/**
 * 将浏览器语言映射到站点 locale（仅支持站内已启用的语言）。
 */
function browserTagToLocale(tag) {
  if (!tag || typeof tag !== "string") {
    return DEFAULT_LOCALE;
  }
  const t = tag.toLowerCase();
  if (t.startsWith("zh")) {
    return "zh-Hans";
  }
  if (t.startsWith("ja")) {
    return "ja";
  }
  if (t.startsWith("ko")) {
    return "ko";
  }
  if (t.startsWith("es")) {
    return "es";
  }
  if (t.startsWith("en")) {
    return "en";
  }
  return DEFAULT_LOCALE;
}

function preferredLocaleFromNavigator() {
  const list =
    typeof navigator !== "undefined" &&
    Array.isArray(navigator.languages) &&
    navigator.languages.length > 0
      ? navigator.languages
      : [navigator.language];
  for (const raw of list) {
    const loc = browserTagToLocale(raw);
    if (loc !== DEFAULT_LOCALE) {
      return loc;
    }
  }
  return browserTagToLocale(navigator.language);
}

/**
 * URL 首段若为已知 locale，则认为用户已在该语言路径下；否则视为默认语言（无前缀）。
 */
function pathImpliedLocale(pathname) {
  const seg = pathname.split("/").filter(Boolean)[0];
  if (seg && LOCALES.has(seg)) {
    return seg;
  }
  return DEFAULT_LOCALE;
}

function buildLocalizedPath(pathname, locale) {
  if (locale === DEFAULT_LOCALE) {
    return pathname;
  }
  if (pathname === "/" || pathname === "") {
    return `/${locale}/`;
  }
  return `/${locale}${pathname}`;
}

/** 去掉显式的默认语言前缀（若存在），避免出现 /en/zh-Hans/... */
function pathForLocaleSwitch(pathname) {
  const parts = pathname.split("/").filter(Boolean);
  if (parts[0] === DEFAULT_LOCALE) {
    const rest = parts.slice(1).join("/");
    return rest ? `/${rest}` : "/";
  }
  return pathname || "/";
}

function tryRedirect() {
  if (!ExecutionEnvironment.canUseDOM) {
    return;
  }
  /** 开发模式一次只编一种语言，跳转到 /en/ 等易导致 404 */
  if (process.env.NODE_ENV === "development") {
    return;
  }

  try {
    if (globalThis.localStorage?.getItem(SKIP_AUTO_KEY) === "1") {
      return;
    }
  } catch {
    // private mode / blocked
  }

  const url = new URL(window.location.href);
  if (url.searchParams.has("noredir")) {
    try {
      globalThis.localStorage?.setItem(SKIP_AUTO_KEY, "1");
    } catch {
      /* ignore */
    }
    url.searchParams.delete("noredir");
    const next = url.pathname + url.search + url.hash;
    window.history.replaceState(null, "", next);
    return;
  }

  const { pathname, search, hash } = window.location;
  const implied = pathImpliedLocale(pathname);
  if (implied !== DEFAULT_LOCALE) {
    return;
  }

  const preferred = preferredLocaleFromNavigator();
  if (preferred === DEFAULT_LOCALE) {
    return;
  }

  const basePath = pathForLocaleSwitch(pathname);
  const nextPath = buildLocalizedPath(basePath, preferred);
  const dest = nextPath + search + hash;
  if (dest === pathname + search + hash) {
    return;
  }
  window.location.replace(dest);
}

if (ExecutionEnvironment.canUseDOM) {
  tryRedirect();
}

export function onRouteUpdate() {
  tryRedirect();
}
