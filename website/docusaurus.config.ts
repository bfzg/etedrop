import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: "EteDrop",
  tagline: "快速、隐私、简单、安全的文件传输与分享",
  favicon: "/favicon.ico",
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },
  url: "https://etedrop.com",
  baseUrl: "/",
  projectName: "EteDrop",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",

  /** 国内镜像站（DNS 指向中国机）；主站 etedrop.com 上展示顶部引导条 */
  customFields: {
    chinaMirrorOrigin:
      process.env.CHINA_MIRROR_ORIGIN ?? "https://cn.etedrop.com",
    /** 本地调试：设为 true 时在非主站域名也显示引导条（需 rebuild） */
    cnMirrorBannerDebug: process.env.CN_MIRROR_BANNER_DEBUG === "1",
  },

  i18n: {
    defaultLocale: "zh-Hans",
    locales: ["zh-Hans", "en", "ja", "es", "ko"],
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
    {
      src: "https://hm.baidu.com/hm.js?b077fe346c836d558d307ca07fbd615a",
      async: true,
    },
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
          sidebarPath: "./sidebars.ts",
        },
        theme: {
          customCss: "./src/css/custom.css",
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
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
          type: "docSidebar",
          to: "/docs",
          label: "文档",
          sidebarId: "docSidebar",
        },
        {
          to: "/down",
          position: "left",
          label: "下载",
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
