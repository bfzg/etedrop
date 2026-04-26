import ExecutionEnvironment from "@docusaurus/ExecutionEnvironment";
import i18n from "@generated/i18n";

/** URL 第一段若与当前 dev 编译语言不一致，则为无效路由（Docusaurus dev 一次只编一种 locale）。 */
const LOCALE_SEGMENTS = new Set(i18n.locales);

function pathImpliedLocale(pathname) {
  const seg = pathname.split("/").filter(Boolean)[0];
  if (seg && LOCALE_SEGMENTS.has(seg)) {
    return seg;
  }
  return null;
}

function warnIfDevLocaleMismatch() {
  if (!ExecutionEnvironment.canUseDOM) {
    return;
  }
  if (process.env.NODE_ENV !== "development") {
    return;
  }
  const implied = pathImpliedLocale(window.location.pathname);
  if (!implied || implied === i18n.currentLocale) {
    return;
  }
  // eslint-disable-next-line no-console
  console.warn(
    `[Docusaurus i18n] 开发模式一次只编译一种语言，当前为「${i18n.currentLocale}」，而地址前缀是「${implied}」。这样会出现 404、图片或视频加载失败。请使用 npm run start（国际默认 en）或 npm run start:${implied}；国内默认语言请用 npm run start:domestic；全语言请用 npm run preview。`,
  );
}

if (ExecutionEnvironment.canUseDOM) {
  warnIfDevLocaleMismatch();
}

export function onRouteUpdate() {
  warnIfDevLocaleMismatch();
}
