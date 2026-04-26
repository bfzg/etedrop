import ExecutionEnvironment from "@docusaurus/ExecutionEnvironment";
import i18n from "@generated/i18n";

const DEFAULT_LOCALE = i18n.defaultLocale;

/** 与 docusaurus.config 的 i18n.locales 一致（随国际/国内构建变化） */
const LOCALES = new Set(i18n.locales);

const SKIP_AUTO_KEY = "etedrop.i18n.skipAuto";
/** 用户手动选择或曾停留过的语言；存在时优先于浏览器语言 */
const USER_LOCALE_KEY = "etedrop.i18n.userLocale";
/** 记录 userLocale 的来源：user=用户选择/明确进入；auto=自动识别跳转 */
const USER_LOCALE_SOURCE_KEY = "etedrop.i18n.userLocaleSource";

function getUserLocalePref() {
  try {
    const v = globalThis.localStorage?.getItem(USER_LOCALE_KEY);
    if (v && LOCALES.has(v)) {
      return v;
    }
  } catch {
    /* private mode */
  }
  return null;
}

function getUserLocaleSource() {
  try {
    const v = globalThis.localStorage?.getItem(USER_LOCALE_SOURCE_KEY);
    return v === "auto" || v === "user" ? v : null;
  } catch {
    return null;
  }
}

function setUserLocalePref(locale, source = "user") {
  if (!LOCALES.has(locale)) {
    return;
  }
  try {
    globalThis.localStorage?.setItem(USER_LOCALE_KEY, locale);
    globalThis.localStorage?.setItem(USER_LOCALE_SOURCE_KEY, source);
  } catch {
    /* ignore */
  }
}

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

  // 严格遵循浏览器偏好顺序：取第一个能映射到站点 locale 的语言。
  for (const raw of list) {
    const loc = browserTagToLocale(raw);
    if (LOCALES.has(loc)) {
      return loc;
    }
  }
  return DEFAULT_LOCALE;
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

/** 去掉显式的默认语言前缀（若存在），避免出现 /en/zh-Hans/... 等重复前缀 */
function pathForLocaleSwitch(pathname) {
  const parts = pathname.split("/").filter(Boolean);
  if (parts[0] === DEFAULT_LOCALE) {
    const rest = parts.slice(1).join("/");
    return rest ? `/${rest}` : "/";
  }
  return pathname || "/";
}

function sameOriginReferrerLocale() {
  try {
    if (!document.referrer) {
      return null;
    }
    const ref = new URL(document.referrer);
    const cur = new URL(window.location.href);
    if (ref.origin !== cur.origin) {
      return null;
    }
    return pathImpliedLocale(ref.pathname);
  } catch {
    return null;
  }
}

function bindLocaleLinkPreferenceCapture() {
  if (!ExecutionEnvironment.canUseDOM) {
    return;
  }
  if (globalThis.__etedropLocaleClickBound) {
    return;
  }
  globalThis.__etedropLocaleClickBound = true;

  document.addEventListener(
    "click",
    (ev) => {
      const target = ev.target;
      if (!(target instanceof Element)) {
        return;
      }
      const link = target.closest("a[href]");
      if (!(link instanceof HTMLAnchorElement)) {
        return;
      }
      const rawHref = link.getAttribute("href");
      if (!rawHref) {
        return;
      }
      // 只处理同站跳转；语言下拉通常是站内链接。
      let nextUrl;
      try {
        nextUrl = new URL(rawHref, window.location.origin);
      } catch {
        return;
      }
      if (nextUrl.origin !== window.location.origin) {
        return;
      }
      const nextLocale = pathImpliedLocale(nextUrl.pathname);
      if (LOCALES.has(nextLocale)) {
        setUserLocalePref(nextLocale, "user");
      }
    },
    true,
  );
}

/**
 * SPA 内从带语言前缀路径切到无前缀路径，视为用户选择了默认语言（英语）。
 */
export function onRouteUpdate({ previousLocation, location } = {}) {
  if (!ExecutionEnvironment.canUseDOM) {
    return;
  }
  if (previousLocation?.pathname != null && location?.pathname != null) {
    const prevLocale = pathImpliedLocale(previousLocation.pathname);
    const nextLocale = pathImpliedLocale(location.pathname);
    if (prevLocale !== DEFAULT_LOCALE && nextLocale === DEFAULT_LOCALE) {
      setUserLocalePref(DEFAULT_LOCALE, "user");
    }
  }
  tryRedirect();
}

function tryRedirect() {
  if (!ExecutionEnvironment.canUseDOM) {
    return;
  }
  /** 开发模式一次只编一种语言，自动跳转到其它语言前缀易导致 404 */
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
      setUserLocalePref(DEFAULT_LOCALE, "user");
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

  /** 已在带前缀的语言路径上：记入偏好并勿再跳转 */
  if (implied !== DEFAULT_LOCALE) {
    const saved = getUserLocalePref();
    const savedSource = getUserLocaleSource();
    // 若这是自动跳转落地页，不要把 auto 覆盖成 user。
    if (saved === implied && savedSource) {
      return;
    }
    setUserLocalePref(implied, "user");
    return;
  }

  // 从其它语言前缀页经站内导航回到无前缀（默认英语）时，保留“用户选择默认语言”。
  const refLocale = sameOriginReferrerLocale();
  if (refLocale && refLocale !== DEFAULT_LOCALE) {
    setUserLocalePref(DEFAULT_LOCALE, "user");
  }

  const basePath = pathForLocaleSwitch(pathname);
  const saved = getUserLocalePref();
  const savedSource = getUserLocaleSource();
  const destFor = (locale) =>
    locale === DEFAULT_LOCALE
      ? basePath + search + hash
      : buildLocalizedPath(basePath, locale) + search + hash;

  /** 用户曾选过非默认语言：回到无前缀 URL 时仍应进对应语言前缀 */
  if (saved && saved !== DEFAULT_LOCALE) {
    // 若该偏好来源于自动识别，而浏览器当前明确偏好默认语言，则不要强制跳到其它 locale。
    const navPreferred = preferredLocaleFromNavigator();
    if (savedSource === "auto" && navPreferred === DEFAULT_LOCALE) {
      setUserLocalePref(DEFAULT_LOCALE, "auto");
      return;
    }
    const dest = destFor(saved);
    if (dest !== pathname + search + hash) {
      window.location.replace(dest);
    }
    return;
  }

  /**
   * 以下：当前为默认（无前缀）路径，且保存的偏好为 null 或默认语言。
   * saved === DEFAULT_LOCALE：明确要默认语言站，不要用浏览器覆盖。
   */
  if (saved === DEFAULT_LOCALE) {
    return;
  }

  /** 从未保存过偏好：仅此时按浏览器语言自动跳转 */
  const preferred = preferredLocaleFromNavigator();
  if (preferred === DEFAULT_LOCALE) {
    setUserLocalePref(DEFAULT_LOCALE, "auto");
    return;
  }

  const dest = destFor(preferred);
  if (dest !== pathname + search + hash) {
    setUserLocalePref(preferred, "auto");
    window.location.replace(dest);
  }
}

if (ExecutionEnvironment.canUseDOM) {
  bindLocaleLinkPreferenceCapture();
  tryRedirect();
}
