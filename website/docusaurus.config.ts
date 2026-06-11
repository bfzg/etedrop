import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/** 与国内构建一致：`npm run build:domestic` / `DOMESTIC_SITE=1` → 默认语言 zh-Hans + 备案等 */
const DOMESTIC_SITE =
  process.env.DOMESTIC_SITE === "1" ||
  process.env.DOMESTIC_SITE?.toLowerCase() === "true";

const I18N_DEFAULT_LOCALE = DOMESTIC_SITE ? "zh-Hans" : "en";
const I18N_LOCALES = DOMESTIC_SITE
  ? (["zh-Hans", "en", "ja", "es", "ko"] as const)
  : (["en", "zh-Hans", "ja", "es", "ko"] as const);

const config: Config = {
  title: "EteDrop",
  tagline: DOMESTIC_SITE
    ? "快速、隐私、简单、安全的文件传输与分享"
    : "Fast, private, simple, secure file transfer and sharing",
  favicon: "/favicon.ico",
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },
  url: DOMESTIC_SITE ? "https://etedrop.cn" : "https://etedrop.com",
  baseUrl: "/",
  headTags: [
    {
      tagName: "script",
      attributes: { type: "application/ld+json" },
      innerHTML: JSON.stringify({
        "@context": "https://schema.org",
        "@type": "Organization",
        name: "EteDrop",
        url: DOMESTIC_SITE ? "https://etedrop.cn" : "https://etedrop.com",
        logo: DOMESTIC_SITE
          ? "https://etedrop.cn/img/app_icon.png"
          : "https://etedrop.com/img/app_icon.png",
      }),
    },
    {
      tagName: "script",
      attributes: { type: "application/ld+json" },
      innerHTML: JSON.stringify({
        "@context": "https://schema.org",
        "@type": "WebSite",
        name: "EteDrop",
        url: DOMESTIC_SITE ? "https://etedrop.cn" : "https://etedrop.com",
        inLanguage: DOMESTIC_SITE
          ? ["zh-Hans", "en", "ja", "es", "ko"]
          : ["en", "zh-Hans", "ja", "es", "ko"],
      }),
    },
  ],

  projectName: "EteDrop",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",

  /**
   * 旧版英文在 /en/*，现默认语言为 en（无前缀）。请勿使用 client-redirects 批量生成 /en/* → /*：
   * 与多语言构建产物冲突。请在托管层做 301：见 static/_redirects（Netlify）或部署文档。
   * 历史中文外链：旧 /docs/* 曾指向中文，现同一路径为英文；中文仅在 /zh-Hans/docs/*。需保留中文收录时请在外链或 GSC 中逐步改为带 zh-Hans 前缀的 URL。
   */

  /** 国内镜像站（DNS 指向中国机）；主站 etedrop.com 上展示顶部引导条 */
  customFields: {
    chinaMirrorOrigin:
      process.env.CHINA_MIRROR_ORIGIN ?? "https://etedrop.cn",
    /** 本地调试：设为 true 时在非主站域名也显示引导条（需 rebuild） */
    cnMirrorBannerDebug: process.env.CN_MIRROR_BANNER_DEBUG === "1",
    /**
     * 国内站点：`npm run build:domestic`（已含 DOMESTIC_SITE=1）。
     * 为 true 时默认语言 zh-Hans、中文 sitemap 根路径、页脚 ICP；构建前会运行 prepare 脚本同步英文文档副本。
     */
    domesticSite: DOMESTIC_SITE,
  },

  i18n: {
    defaultLocale: I18N_DEFAULT_LOCALE,
    locales: [...I18N_LOCALES],
    localeConfigs: {
      "zh-Hans": {
        label: "简体中文",
        htmlLang: "zh-Hans",
      },
      en: {
        label: "English",
        htmlLang: "en",
      },
      ja: {
        label: "日本語",
        htmlLang: "ja",
      },
      es: {
        label: "Español",
        htmlLang: "es",
      },
      ko: {
        label: "한국어",
        htmlLang: "ko",
      },
    },
  },

  scripts: [
    {
      src: "https://www.googletagmanager.com/gtag/js?id=G-C5CZDLVNCJ",
      async: true,
    },
    {
      src: "/js/gtag-init.js",
      async: false,
    },
    ...(DOMESTIC_SITE
      ? [
          {
            src: "https://hm.baidu.com/hm.js?2de07b0b8062c52b2a668723cc5637f2",
            async: true,
          },
        ]
      : [
          {
            src: "https://hm.baidu.com/hm.js?b077fe346c836d558d307ca07fbd615a",
            async: true,
          },
        ]),
  ],

  clientModules: [
    require.resolve("./src/scripts/auto-locale.js"),
    require.resolve("./src/scripts/dev-i18n-hint.js"),
    require.resolve("./src/scripts/fix-double-locale.js"),
    require.resolve("./src/scripts/navbar-scroll.js"),
  ],

  presets: [
    [
      "classic",
      {
        docs: {
          /** 国内构建：默认中文内容在 i18n/zh-Hans；国际构建：英文在 /docs */
          path: DOMESTIC_SITE
            ? "i18n/zh-Hans/docusaurus-plugin-content-docs/current"
            : "docs",
          sidebarPath: "./sidebars.ts",
        },
        blog: {
          /** 与 docs 相同：国内默认中文 blog 在 i18n/zh-Hans；国际默认英文在 /blog */
          path: DOMESTIC_SITE
            ? "i18n/zh-Hans/docusaurus-plugin-content-blog"
            : "blog",
          routeBasePath: "blog",
          showReadingTime: true,
          blogTitle: "Blog",
          blogDescription: "Guides on private P2P file transfer, LAN sharing, and EteDrop tips",
          postsPerPage: 10,
          feedOptions: {
            type: "all",
            copyright: `Copyright © ${new Date().getFullYear()} EteDrop`,
          },
        },
        sitemap: {
          changefreq: "weekly",
          priority: 0.7,
          filename: "sitemap.xml",
        },
        theme: {
          customCss: "./src/css/custom.css",
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    metadata: [
      { name: "application-name", content: "EteDrop" },
      { name: "apple-mobile-web-app-title", content: "EteDrop" },
      // Open Graph 全局默认值（页面级 PageMetadata 可覆盖）
      { property: "og:type", content: "website" },
      { property: "og:site_name", content: "EteDrop" },
      {
        property: "og:image",
        content: DOMESTIC_SITE
          ? "https://etedrop.cn/img/og_cover.png"
          : "https://etedrop.com/img/og_cover.png",
      },
      { property: "og:image:width", content: "1200" },
      { property: "og:image:height", content: "630" },
      // Twitter Card
      { name: "twitter:card", content: "summary_large_image" },
      { name: "twitter:site", content: "@EteDrop" },
      {
        name: "twitter:image",
        content: DOMESTIC_SITE
          ? "https://etedrop.cn/img/og_cover.png"
          : "https://etedrop.com/img/og_cover.png",
      },
    ],
    navbar: {
      hideOnScroll: false,
      title: "EteDrop",
      logo: {
        alt: "EteDrop",
        src: "img/app_icon.png",
      },
      items: [
        { to: "/", label: "首页", exact: true },
        {
          // 不用 docSidebar：其 isActive 只看「当前文档是否属于该侧栏」，会强制在 FAQ/联系我们 页也高亮「文档」
          to: "/docs/doc/mac-install-damaged",
          label: "文档",
          activeBaseRegex:
            "^/(?:[a-z]{2}(?:-[a-zA-Z0-9]+)?/)?docs(?!/doc/(faq|contact-us)(/|$))",
        },
        {
          to: "/blog",
          position: "left",
          label: "博客",
        },
        {
          to: "/down",
          position: "left",
          label: "下载",
          exact: true,
        },
        {
          to: "/docs/doc/faq",
          position: "left",
          label: "常见问题",
          exact: true,
        },
        {
          to: "/docs/doc/contact-us",
          position: "left",
          label: "联系我们",
          exact: true,
        },
        {
          type: "localeDropdown",
          position: "right",
        },
      ],
    },
    prism: {},
    colorMode: {
      disableSwitch: true, // 禁用夜晚白天切换按钮
      defaultMode: "light", // 设置默认模式（可以是 'light' 或 'dark'）
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
