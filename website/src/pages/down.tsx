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
  kind: "ready" | "testing";
  fileKey?: "windows" | "macos";
};

const platforms: PlatformRow[] = [
  {
    id: "windows",
    icon: "/img/windows.png",
    kind: "ready",
    fileKey: "windows",
  },
  {
    id: "macos",
    icon: "/img/macos.png",
    kind: "ready",
    fileKey: "macos",
  },
  {
    id: "linux",
    icon: "/img/linux.png",
    kind: "testing",
  },
  {
    id: "ios",
    icon: "/img/ios.png",
    kind: "testing",
  },
  {
    id: "android",
    icon: "/img/android.png",
    kind: "testing",
  },
];

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

function PlatformTitleHint({ id }: { id: string }): ReactNode {
  switch (id) {
    case "windows":
      return (
        <>
          <Heading
            as="h3"
            className="m-0 text-[18px] font-semibold text-slate-800 dark:text-slate-100"
          >
            <Translate id="download.platform.windows.name">Windows</Translate>
          </Heading>
          <span className="mt-2 text-center text-[11px] leading-relaxed text-slate-400 line-clamp-2 dark:text-slate-500">
            <Translate id="download.platform.windows.hint">
              内含精简版、XP特别版
            </Translate>
          </span>
        </>
      );
    case "macos":
      return (
        <>
          <Heading
            as="h3"
            className="m-0 text-[18px] font-semibold text-slate-800 dark:text-slate-100"
          >
            <Translate id="download.platform.macos.name">macOS</Translate>
          </Heading>
          <span className="mt-2 text-center text-[11px] leading-relaxed text-slate-400 line-clamp-2 dark:text-slate-500">
            <Translate id="download.platform.macos.hint">
              适用于 macOS 12 及以上
            </Translate>
          </span>
        </>
      );
    case "linux":
      return (
        <>
          <Heading
            as="h3"
            className="m-0 text-[18px] font-semibold text-slate-800 dark:text-slate-100"
          >
            <Translate id="download.platform.linux.name">Linux</Translate>
          </Heading>
          <span className="mt-2 text-center text-[11px] leading-relaxed text-slate-400 line-clamp-2 dark:text-slate-500">
            <Translate id="download.platform.linux.hint">常见桌面发行版</Translate>
          </span>
        </>
      );
    case "ios":
      return (
        <>
          <Heading
            as="h3"
            className="m-0 text-[18px] font-semibold text-slate-800 dark:text-slate-100"
          >
            <Translate id="download.platform.ios.name">iOS</Translate>
          </Heading>
          <span className="mt-2 text-center text-[11px] leading-relaxed text-slate-400 line-clamp-2 dark:text-slate-500">
            <Translate id="download.platform.ios.hint">iPhone 与 iPad</Translate>
          </span>
        </>
      );
    case "android":
      return (
        <>
          <Heading
            as="h3"
            className="m-0 text-[18px] font-semibold text-slate-800 dark:text-slate-100"
          >
            <Translate id="download.platform.android.name">Android</Translate>
          </Heading>
          <span className="mt-2 text-center text-[11px] leading-relaxed text-slate-400 line-clamp-2 dark:text-slate-500">
            <Translate id="download.platform.android.hint">手机与平板客户端</Translate>
          </span>
        </>
      );
    default:
      return null;
  }
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

        {!isReady && (
          <div className="absolute left-0 top-0 rounded-br-2xl rounded-tl-[28px] bg-gradient-to-br from-amber-400 to-amber-500 px-3 py-1 text-[11px] font-bold text-white shadow-sm dark:from-amber-600 dark:to-amber-700">
            <Translate id="download.badge.testing">测试中</Translate>
          </div>
        )}

        <img
          src={iconSrc}
          alt=""
          className={clsx(
            "mb-5 h-16 w-16 object-contain transition-transform duration-300",
            isReady && "group-hover:scale-110",
          )}
        />

        <PlatformTitleHint id={row.id} />
      </Wrapper>

      <div className="mt-4 text-[13px] text-slate-400 dark:text-slate-500">
        {isReady ? (
          <Translate id="download.platform.status.ready">最新版本</Translate>
        ) : (
          <Translate id="download.platform.status.soon">敬请期待</Translate>
        )}
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
        message: "下载 EteDrop 桌面客户端。",
      })}
    >
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

          <div className="mx-auto mt-16 flex max-w-6xl flex-wrap justify-center gap-6 sm:gap-8">
            {platforms.map((row) => (
              <PlatformCard key={row.id} row={row} />
            ))}
          </div>
        </Container>
      </main>
      <Footer />
    </Layout>
  );
}
