import { useMemo, useState } from "react";
import type { ReactNode } from "react";
import Link from "@docusaurus/Link";
import useBaseUrl from "@docusaurus/useBaseUrl";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import Heading from "@theme/Heading";
import Translate, { translate } from "@docusaurus/Translate";
import Container from "@site/src/components/Container";
import Footer from "@site/src/components/Footer";
import type { ReleaseChangelogEntry } from "@site/src/constant/release";
import {
  useReleaseManifest,
  useResolvedDownloadHref,
} from "@site/src/hooks/useReleaseManifest";
import clsx from "clsx";

type PlatformRow = {
  id: string;
  icon: string;
  fileKey: "windows" | "macos" | "linux" | "ios" | "android";
};

const platforms: PlatformRow[] = [
  { id: "windows", icon: "/img/windows.png", fileKey: "windows" },
  { id: "macos", icon: "/img/macos.png", fileKey: "macos" },
  { id: "linux", icon: "/img/linux.png", fileKey: "linux" },
  { id: "ios", icon: "/img/ios.png", fileKey: "ios" },
  { id: "android", icon: "/img/android.png", fileKey: "android" },
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

function notesLocaleTag(locale: string): keyof ReleaseChangelogEntry["notes"] {
  const l = locale.toLowerCase();
  if (l === "zh-hans" || l.startsWith("zh")) return "zh";
  if (l === "ja") return "ja";
  if (l === "ko") return "ko";
  if (l === "es") return "es";
  return "en";
}

function pickLocalizedLines(
  notes: ReleaseChangelogEntry["notes"],
  locale: string,
): string[] {
  const tag = notesLocaleTag(locale);
  const lines = notes[tag] ?? notes.en ?? notes.zh ?? [];
  return lines.filter(Boolean);
}

type ChangeKind = "new" | "fix" | "improve" | "other";

type ParsedLine = {
  kind: ChangeKind;
  tag: string | null;
  text: string;
};

const KIND_KEYWORDS: Record<ChangeKind, string[]> = {
  new: ["新增", "新机能", "新機能", "新规", "新規", "新版", "首个", "初版", "new", "first", "신규", "첫", "nuevo", "primera"],
  fix: ["修复", "修正", "fixed", "fix", "수정", "corrección", "correccion"],
  improve: ["优化", "改善", "improved", "improve", "개선", "mejora"],
  other: ["其他", "その他", "other", "misc", "기타", "otros"],
};

function classifyTag(tag: string | null): ChangeKind {
  if (!tag) return "other";
  const norm = tag.toLowerCase().trim();
  for (const kind of ["new", "fix", "improve"] as const) {
    if (KIND_KEYWORDS[kind].some((k) => norm.includes(k))) return kind;
  }
  return "other";
}

function parseChangelogLine(line: string): ParsedLine {
  const m = line.match(/^\s*\[([^\]]+)\]\s*(.*)$/);
  if (m) {
    const tag = m[1].trim();
    const text = m[2].trim();
    return { kind: classifyTag(tag), tag, text };
  }
  return { kind: "other", tag: null, text: line.trim() };
}

const KIND_CHIP_CLASS: Record<ChangeKind, string> = {
  new: "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200/80 dark:bg-emerald-500/10 dark:text-emerald-300 dark:ring-emerald-400/30",
  fix: "bg-amber-50 text-amber-700 ring-1 ring-amber-200/80 dark:bg-amber-500/10 dark:text-amber-300 dark:ring-amber-400/30",
  improve: "bg-blue-50 text-blue-700 ring-1 ring-blue-200/80 dark:bg-blue-500/10 dark:text-blue-300 dark:ring-blue-400/30",
  other: "bg-slate-100 text-slate-600 ring-1 ring-slate-200 dark:bg-slate-700/40 dark:text-slate-300 dark:ring-slate-600/60",
};

const KIND_DOT_CLASS: Record<ChangeKind, string> = {
  new: "bg-emerald-500",
  fix: "bg-amber-500",
  improve: "bg-blue-500",
  other: "bg-slate-400",
};

function ChangelogLine({ line }: { line: ParsedLine }): ReactNode {
  return (
    <li className="flex items-start gap-3 leading-relaxed">
      <span
        aria-hidden="true"
        className={clsx(
          "mt-2 h-1.5 w-1.5 shrink-0 rounded-full",
          KIND_DOT_CLASS[line.kind],
        )}
      />
      <div className="flex flex-wrap items-baseline gap-x-2 gap-y-1 text-[15px]">
        {line.tag ? (
          <span
            className={clsx(
              "inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-medium tracking-wide",
              KIND_CHIP_CLASS[line.kind],
            )}
          >
            {line.tag}
          </span>
        ) : null}
        <span className="text-slate-600 dark:text-slate-300">{line.text}</span>
      </div>
    </li>
  );
}

function VersionEntry({
  entry,
  lines,
  isLatest,
}: {
  entry: ReleaseChangelogEntry;
  lines: ParsedLine[];
  isLatest: boolean;
}): ReactNode {
  return (
    <li className="relative pl-10">
      {/* timeline dot */}
      <span
        aria-hidden="true"
        className={clsx(
          "absolute left-[14px] top-2 inline-flex h-3 w-3 -translate-x-1/2 items-center justify-center rounded-full ring-4",
          isLatest
            ? "bg-blue-500 ring-blue-100 dark:bg-blue-400 dark:ring-blue-500/20"
            : "bg-white ring-slate-200 dark:bg-slate-800 dark:ring-slate-700",
        )}
      >
        {!isLatest ? (
          <span className="h-1.5 w-1.5 rounded-full bg-slate-300 dark:bg-slate-600" />
        ) : null}
      </span>

      <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
        <Heading
          as="h3"
          className="m-0 text-lg font-semibold text-slate-800 dark:text-slate-100"
        >
          v{entry.version}
        </Heading>
        {isLatest ? (
          <span className="inline-flex items-center rounded-full bg-blue-50 px-2.5 py-0.5 text-[11px] font-semibold uppercase tracking-wide text-blue-700 ring-1 ring-blue-200/80 dark:bg-blue-500/10 dark:text-blue-300 dark:ring-blue-400/30">
            <Translate id="download.changelog.latestPill">最新</Translate>
          </span>
        ) : null}
      </div>

      <ul className="mt-3 list-none space-y-2 p-0">
        {lines.map((line, idx) => (
          <ChangelogLine key={`${entry.version}-${idx}`} line={line} />
        ))}
      </ul>
    </li>
  );
}

function ChangelogSection({
  entries,
  latestVersion,
}: {
  entries: ReleaseChangelogEntry[];
  latestVersion: string;
}): ReactNode {
  const { i18n } = useDocusaurusContext();
  const loc = i18n.currentLocale;
  const [showAll, setShowAll] = useState(false);

  const visible = useMemo(
    () =>
      entries
        .map((entry) => ({
          entry,
          lines: pickLocalizedLines(entry.notes, loc).map(parseChangelogLine),
        }))
        .filter((x) => x.lines.length > 0),
    [entries, loc],
  );

  const VISIBLE_COUNT = 2;
  const hasMore = visible.length > VISIBLE_COUNT;
  const shown = showAll ? visible : visible.slice(0, VISIBLE_COUNT);

  return (
    <section
      id="changelog"
      className="mx-auto mt-24 max-w-3xl scroll-mt-24 text-left"
    >
      <div className="text-center">
        <span className="inline-flex items-center rounded-full bg-blue-50 px-3 py-1 text-[12px] font-semibold uppercase tracking-wide text-blue-700 ring-1 ring-blue-200/80 dark:bg-blue-500/10 dark:text-blue-300 dark:ring-blue-400/30">
          <Translate id="download.changelog.kicker">CHANGELOG</Translate>
        </span>
        <Heading
          as="h2"
          className="mt-4 text-2xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-3xl"
        >
          <Translate id="download.changelog.title">更新日志</Translate>
        </Heading>
      </div>

      <div className="mt-10 rounded-3xl border border-slate-200/80 bg-white/80 p-6 shadow-[0_18px_50px_-30px_rgba(15,23,42,0.25)] backdrop-blur-sm sm:p-10 dark:border-slate-700/60 dark:bg-slate-900/70 dark:shadow-[0_28px_60px_-30px_rgba(0,0,0,0.55)]">
        {visible.length === 0 ? (
          <p className="text-center text-[15px] text-slate-500 dark:text-slate-400">
            <Translate id="download.changelog.empty">暂无记录。</Translate>
          </p>
        ) : (
          <>
            <ol className="relative m-0 list-none space-y-10 p-0 before:absolute before:left-[14px] before:top-2 before:h-[calc(100%-1rem)] before:w-px before:bg-gradient-to-b before:from-slate-200 before:via-slate-200 before:to-transparent dark:before:from-slate-700 dark:before:via-slate-700">
              {shown.map(({ entry, lines }, idx) => (
                <VersionEntry
                  key={entry.version}
                  entry={entry}
                  lines={lines}
                  isLatest={idx === 0 && entry.version === latestVersion}
                />
              ))}
            </ol>
            {hasMore ? (
              <div className="mt-8 flex justify-center">
                <button
                  type="button"
                  onClick={() => setShowAll((v) => !v)}
                  className="group inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-4 py-2 text-[13px] font-medium text-slate-600 transition hover:border-blue-200 hover:text-blue-600 hover:shadow-sm dark:border-slate-700 dark:bg-slate-800/70 dark:text-slate-300 dark:hover:border-blue-400/40 dark:hover:text-blue-300"
                >
                  {showAll ? (
                    <Translate id="download.changelog.hideOlder">收起更早的版本</Translate>
                  ) : (
                    <Translate id="download.changelog.showOlder">显示更早的版本</Translate>
                  )}
                  <svg
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                    className={clsx(
                      "h-4 w-4 transition-transform",
                      showAll ? "rotate-180" : "rotate-0",
                    )}
                  >
                    <path
                      fillRule="evenodd"
                      d="M5.23 7.21a.75.75 0 011.06.02L10 11.06l3.71-3.83a.75.75 0 111.08 1.04l-4.25 4.39a.75.75 0 01-1.08 0L5.21 8.27a.75.75 0 01.02-1.06z"
                      clipRule="evenodd"
                    />
                  </svg>
                </button>
              </div>
            ) : null}
          </>
        )}
      </div>
    </section>
  );
}

function PlatformCard({
  row,
  downloadHref,
  version,
}: {
  row: PlatformRow;
  downloadHref: string;
  version: string;
}): ReactNode {
  const iconSrc = useBaseUrl(row.icon);
  const href = downloadHref.trim();
  const isReady = href.length > 0;
  const Wrapper = isReady ? "a" : "div";

  return (
    <div className="flex flex-col items-center">
      <Wrapper
        href={isReady ? href : undefined}
        download={isReady ? true : undefined}
        className={clsx(
          "group relative flex h-[220px] w-[190px] flex-col items-center justify-center rounded-[28px] bg-white p-6 no-underline transition-all duration-300 hover:no-underline focus:no-underline dark:bg-slate-900 [&_*]:no-underline hover:[&_*]:no-underline",
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

      <div className="mt-4 flex flex-col items-center gap-2 text-[13px] text-slate-400 dark:text-slate-500">
        <div className="text-center">
          {isReady ? (
            <>
              <Translate id="download.platform.status.ready">最新版本</Translate>
              {version ? ` · v${version}` : null}
            </>
          ) : (
            <Translate id="download.platform.status.soon">敬请期待</Translate>
          )}
        </div>
        {row.id === "macos" ? (
          <Link
            to="/docs/doc/mac-install-damaged"
            className="text-[13px] font-medium text-blue-600 no-underline hover:text-blue-700 hover:no-underline dark:text-blue-400 dark:hover:text-blue-300"
          >
            <Translate id="download.platform.macos.installDoc">查看安装文档</Translate>
          </Link>
        ) : null}
      </div>
    </div>
  );
}

export default function DownPage(): ReactNode {
  const manifest = useReleaseManifest();
  /** `version.json` 中填完整 https 链接时，各语言路由不会改写路径；相对路径仍走 `useResolvedDownloadHref` */
  const hrefByKey = {
    windows: useResolvedDownloadHref(manifest.windowsDownloadUrl),
    macos: useResolvedDownloadHref(manifest.macDownloadUrl),
    linux: useResolvedDownloadHref(manifest.linuxDownloadUrl),
    ios: useResolvedDownloadHref(manifest.iosDownloadUrl),
    android: useResolvedDownloadHref(manifest.androidDownloadUrl),
  } as const;
  const versionByKey = {
    windows: manifest.windowsVersion,
    macos: manifest.macVersion,
    linux: manifest.linuxVersion,
    ios: manifest.iosVersion,
    android: manifest.androidVersion,
  } as const;

  return (
    <Layout
      title={translate({ id: "download.meta.title", message: "下载" })}
      description={translate({
        id: "download.meta.description",
        message: "下载 EteDrop 桌面客户端。",
      })}
    >
      <main className="relative isolate overflow-hidden bg-gradient-to-b from-slate-50 via-white to-white pb-24 pt-16 dark:from-slate-950 dark:via-slate-950 dark:to-slate-950">
        {/* 顶部柔和蓝色光晕 */}
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-[520px] bg-[radial-gradient(620px_320px_at_50%_-10%,rgba(32,131,255,0.18),transparent_70%),radial-gradient(420px_240px_at_15%_5%,rgba(96,165,250,0.14),transparent_70%),radial-gradient(420px_240px_at_85%_5%,rgba(168,206,255,0.16),transparent_70%)] dark:bg-[radial-gradient(620px_320px_at_50%_-10%,rgba(32,131,255,0.22),transparent_70%),radial-gradient(420px_240px_at_15%_5%,rgba(96,165,250,0.16),transparent_70%),radial-gradient(420px_240px_at_85%_5%,rgba(168,206,255,0.16),transparent_70%)]"
        />
        {/* 极淡点阵 */}
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 -z-10 opacity-[0.18] [mask-image:radial-gradient(ellipse_at_top,black_30%,transparent_75%)] dark:opacity-[0.22]"
          style={{
            backgroundImage:
              "radial-gradient(circle at 1px 1px, rgba(15,23,42,0.55) 1px, transparent 0)",
            backgroundSize: "22px 22px",
          }}
        />

        <Container>
          <div className="mx-auto max-w-3xl text-center">
            <Heading
              as="h1"
              className="text-4xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-5xl"
            >
              <Translate id="download.page.title">下载中心</Translate>
            </Heading>
            <p className="mt-5 text-[15px] leading-relaxed text-slate-500 dark:text-slate-400 sm:text-[16px]">
              <Translate id="download.page.subtitle">
                选择您的系统获取桌面客户端。移动端与 Linux 版本正在加紧测试中。
              </Translate>
            </p>
            {manifest.latestVersion && manifest.latestVersion !== "0.0.0" ? (
              <div className="mt-6 flex justify-center">
                <Link
                  to="#changelog"
                  className="group inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white/70 px-4 py-1.5 text-[13px] font-medium text-slate-600 no-underline shadow-sm backdrop-blur-sm transition hover:border-blue-200 hover:text-blue-600 hover:no-underline dark:border-slate-700/70 dark:bg-slate-900/60 dark:text-slate-300 dark:hover:border-blue-400/40 dark:hover:text-blue-300"
                >
                  <span className="inline-flex h-1.5 w-1.5 rounded-full bg-emerald-500" />
                  v{manifest.latestVersion}
                  <span className="text-slate-300 dark:text-slate-600">·</span>
                  <span>
                    <Translate id="download.changelog.viewLink">查看更新日志</Translate>
                  </span>
                  <svg
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                    className="h-3.5 w-3.5 translate-y-px text-slate-400 transition group-hover:translate-y-0.5 group-hover:text-blue-500 dark:text-slate-500"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 3a.75.75 0 01.75.75v10.94l3.72-3.72a.75.75 0 111.06 1.06l-5 5a.75.75 0 01-1.06 0l-5-5a.75.75 0 111.06-1.06l3.72 3.72V3.75A.75.75 0 0110 3z"
                      clipRule="evenodd"
                    />
                  </svg>
                </Link>
              </div>
            ) : null}
          </div>

          <div className="mx-auto mt-14 flex max-w-6xl flex-wrap justify-center gap-6 sm:gap-8">
            {platforms.map((row) => (
              <PlatformCard
                key={row.id}
                row={row}
                downloadHref={hrefByKey[row.fileKey]}
                version={versionByKey[row.fileKey]}
              />
            ))}
          </div>

          <ChangelogSection
            entries={manifest.changelog}
            latestVersion={manifest.latestVersion}
          />
        </Container>
      </main>
      <Footer />
    </Layout>
  );
}
