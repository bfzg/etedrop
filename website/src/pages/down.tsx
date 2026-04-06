import type { ReactNode } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import Layout from "@theme/Layout";
import Heading from "@theme/Heading";
import Translate, { translate } from "@docusaurus/Translate";
import Container from "@site/src/components/Container";
import Footer from "@site/src/components/Footer";
import { DOWNLOAD_INSTALLERS } from "@site/src/constant/downloads";
import clsx from "clsx";

type PlatformRow = {
  id: string;
  icon: string;
  nameId: string;
  nameDefault: string;
  hintId: string;
  hintDefault: string;
  kind: "ready" | "testing";
  fileKey?: "windows" | "macos";
};

const platforms: PlatformRow[] = [
  {
    id: "windows",
    icon: "/img/windows.png",
    nameId: "download.platform.windows.name",
    nameDefault: "Windows",
    hintId: "download.platform.windows.hint",
    hintDefault: "内含精简版、XP特别版", // 根据你的图片稍微改了下文案做示例
    kind: "ready",
    fileKey: "windows",
  },
  {
    id: "macos",
    icon: "/img/macos.png",
    nameId: "download.platform.macos.name",
    nameDefault: "macOS",
    hintId: "download.platform.macos.hint",
    hintDefault: "适用于 macOS 12 及以上",
    kind: "ready",
    fileKey: "macos",
  },
  {
    id: "linux",
    icon: "/img/linux.png",
    nameId: "download.platform.linux.name",
    nameDefault: "Linux",
    hintId: "download.platform.linux.hint",
    hintDefault: "常见桌面发行版",
    kind: "testing",
  },
  {
    id: "ios",
    icon: "/img/ios.png",
    nameId: "download.platform.ios.name",
    nameDefault: "iOS",
    hintId: "download.platform.ios.hint",
    hintDefault: "iPhone 与 iPad",
    kind: "testing",
  },
  {
    id: "android",
    icon: "/img/android.png",
    nameId: "download.platform.android.name",
    nameDefault: "Android",
    hintId: "download.platform.android.hint",
    hintDefault: "手机与平板客户端",
    kind: "testing",
  },
];

// 右上角下载小图标 SVG
function DownloadIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5"
    >
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="7 10 12 15 17 10" />
      <line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}

// 右上角敬请期待/时钟小图标 SVG
function WaitIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5"
    >
      <circle cx="12" cy="12" r="10" />
      <polyline points="12 6 12 12 16 14" />
    </svg>
  );
}

function PlatformCard({ row }: { row: PlatformRow }): ReactNode {
  const iconSrc = useBaseUrl(row.icon);
  const urlWindows = useBaseUrl(DOWNLOAD_INSTALLERS.windows);
  const urlMacos = useBaseUrl(DOWNLOAD_INSTALLERS.macos);
  const href =
    row.fileKey === "windows"
      ? urlWindows
      : row.fileKey === "macos"
        ? urlMacos
        : undefined;

  const isReady = row.kind === "ready";

  // 核心：如果是 ready 状态，卡片本身就是个 <a> 链接，否则是 <div>
  const Wrapper = isReady ? "a" : "div";

  return (
    <div className="flex flex-col items-center">
      <Wrapper
        href={isReady ? href : undefined}
        download={isReady ? true : undefined}
        className={clsx(
          "group relative flex h-[220px] w-[190px] flex-col items-center justify-center rounded-[28px] bg-white p-6 transition-all duration-300 dark:bg-slate-900",
          isReady
            ? "cursor-pointer shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:-translate-y-1.5 hover:shadow-[0_12px_32px_rgba(0,0,0,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.4)] dark:hover:shadow-[0_12px_32px_rgba(0,0,0,0.6)]"
            : "cursor-not-allowed border border-slate-100 bg-slate-50/50 opacity-90 dark:border-slate-800 dark:bg-slate-900/50",
        )}
      >
        {/* 右上角图标：参考图片中的小箭头/二维码位置 */}
        <div
          className={clsx(
            "absolute right-4 top-4 transition-colors duration-300",
            isReady
              ? "text-slate-400 group-hover:text-blue-500 dark:text-slate-500"
              : "text-slate-300 dark:text-slate-600",
          )}
        >
          {isReady ? <DownloadIcon /> : <WaitIcon />}
        </div>

        {/* 左上角状态徽标 (测试中) */}
        {!isReady && (
          <div className="absolute left-0 top-0 rounded-br-2xl rounded-tl-[28px] bg-gradient-to-br from-amber-400 to-amber-500 px-3 py-1 text-[11px] font-bold text-white shadow-sm dark:from-amber-600 dark:to-amber-700">
            <Translate id="download.badge.testing">测试中</Translate>
          </div>
        )}

        {/* 操作系统 Logo */}
        <img
          src={iconSrc}
          alt=""
          className={clsx(
            "mb-5 h-16 w-16 object-contain transition-transform duration-300",
            isReady && "group-hover:scale-110", // 悬停放大动画
          )}
        />

        {/* 名称与描述 */}
        <Heading
          as="h3"
          className="m-0 text-[18px] font-semibold text-slate-800 dark:text-slate-100"
        >
          <Translate id={row.nameId}>{row.nameDefault}</Translate>
        </Heading>

        <span className="mt-2 text-center text-[11px] leading-relaxed text-slate-400 line-clamp-2 dark:text-slate-500">
          <Translate id={row.hintId}>{row.hintDefault}</Translate>
        </span>
      </Wrapper>

      {/* 底部版本号占位 (对应图片下方灰色的 V4.8.7.5 等，这里如果没有真实数据可以用统一文案或隐藏) */}
      <div className="mt-4 text-[13px] text-slate-400 dark:text-slate-500">
        {isReady ? "最新版本" : "敬请期待"}
      </div>
    </div>
  );
}

export default function DownPage(): ReactNode {
  return (
    <Layout
      title={translate({ id: "download.meta.title", message: "下载" })}
      description={translate({
        id: "download.meta.description",
        message: "下载 EteDrop 桌面客户端...",
      })}
    >
      {/* 背景增加了非常微弱的蓝色渐变，呼应原图头部的天蓝色柔和光效 */}
      <main className="h-[calc(100vh-100px)] bg-gray-50 flex items-center justify-center">
        <Container>
          <div className="mx-auto max-w-3xl text-center">
            <Heading
              as="h1"
              className="text-4xl font-bold tracking-tight text-slate-900 dark:text-white"
            >
              <Translate id="download.page.title">下载中心</Translate>
            </Heading>
            <p className="mt-5 text-[15px] text-slate-500 dark:text-slate-400">
              <Translate id="download.page.subtitle">
                选择您的系统获取桌面客户端。移动端与 Linux 版本正在加紧测试中。
              </Translate>
            </p>
          </div>

          {/* 使用 flex 弹性布局居中卡片，自动换行，完美还原一排排列的效果 */}
          <div className="mx-auto mt-16 flex max-w-6xl flex-wrap justify-center gap-6 sm:gap-8">
            {platforms.map((row) => (
              <PlatformCard key={row.id} row={row} />
            ))}
          </div>

          {/* <p className="mx-auto mt-16 max-w-2xl text-center text-sm text-slate-400 dark:text-slate-500">
            <Translate id="download.page.note">
              若下载后无法打开安装包，请在系统设置中允许来自已识别开发者的应用，或联系支持获取最新构建。
            </Translate>
          </p> */}
        </Container>
      </main>
      <Footer />
    </Layout>
  );
}
