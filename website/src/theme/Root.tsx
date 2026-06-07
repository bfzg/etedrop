/**
 * Root swizzle — 注入跨站 hreflang 标签与 x-default
 *
 * Docusaurus 内置已为同站多语言页面生成 hreflang alternate，本组件补充：
 *   1. x-default → 始终指向 etedrop.com（国际英文版根路径）
 *   2. 跨站声明：
 *      - 国内站（etedrop.cn）：声明 zh-Hans 同时也存在于 etedrop.com/zh-Hans/
 *      - 国际站（etedrop.com）：声明 zh-Hans 同时也存在于 etedrop.cn/
 *
 * 注意：Docusaurus 的内置 hreflang 已覆盖同站语言切换，本组件不重复注入，
 *       仅补充跨域互指与 x-default，避免重复标签。
 */
import type { ReactNode } from "react";
import { useLocation } from "@docusaurus/router";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Head from "@docusaurus/Head";

/**
 * 从当前路径中剥离语言前缀，返回无前缀的路径（始终以 / 开头）。
 * 例如：/zh-Hans/docs/doc/faq → /docs/doc/faq
 *       /docs/doc/faq         → /docs/doc/faq
 */
function stripLocalePrefix(pathname: string, locales: string[]): string {
  for (const locale of locales) {
    if (
      pathname === `/${locale}` ||
      pathname.startsWith(`/${locale}/`)
    ) {
      return pathname.slice(`/${locale}`.length) || "/";
    }
  }
  return pathname;
}

export default function Root({ children }: { children: ReactNode }): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  const { pathname } = useLocation();

  const isDomestic =
    (siteConfig.customFields as Record<string, unknown>)?.domesticSite === true;

  const locales = siteConfig.i18n.locales;
  const cleanPath = stripLocalePrefix(pathname, locales);

  // 国际站 base URL
  const intlBase = "https://etedrop.com";
  // 国内站 base URL
  const cnBase = "https://etedrop.cn";

  /**
   * x-default 始终指向国际站英文版（无前缀 = 默认 en）。
   * 若当前在国内站，x-default 需要跨域指向 etedrop.com。
   * 若当前在国际站，x-default 指向同站的英文（无前缀）路径。
   */
  const xDefaultHref = `${intlBase}${cleanPath}`;

  /**
   * 跨站 zh-Hans 互指：
   * - 国内站（默认 zh-Hans，无前缀）：声明 etedrop.com/zh-Hans{cleanPath} 也是同一中文内容
   * - 国际站（zh-Hans 有 /zh-Hans/ 前缀）：声明 etedrop.cn{cleanPath} 也是同一中文内容
   */
  const crossZhHref = isDomestic
    ? `${intlBase}/zh-Hans${cleanPath === "/" ? "" : cleanPath}`
    : `${cnBase}${cleanPath}`;

  return (
    <>
      <Head>
        {/* x-default: 指向国际英文版 */}
        <link rel="alternate" hrefLang="x-default" href={xDefaultHref} />
        {/* 跨站 zh-Hans 互指 */}
        <link rel="alternate" hrefLang="zh-Hans" href={crossZhHref} />
      </Head>
      {children}
    </>
  );
}
