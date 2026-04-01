import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: "Eddy",
  tagline: "快速、安全的文件传输与分享",
  favicon: "/favicon.ico",
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },
  url: "https://fasteddy.com",
  baseUrl: "/",
  projectName: "Eddy",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",

  i18n: {
    defaultLocale: "zh-Hans",
    locales: ["zh-Hans"],
  },

  scripts: [
    {
      src: "https://hm.baidu.com/hm.js?5a4a07b95eeecd2ad5b617aee9592657",
      async: true,
    },
  ],

  clientModules: [require.resolve("./src/scripts/navbar-scroll.js")],

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
      title: "Eddy",
      logo: {
        alt: "Eddy",
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
          label: "定价",
          href: "/#price",
          target: "_self",
          exact: true,
        },
        {
          to: "/down/index",
          position: "left",
          label: "下载",
          exact: true,
        },
        {
          label: "支持",
          href: "/#footer",
          target: "_self",
          exact: true,
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
