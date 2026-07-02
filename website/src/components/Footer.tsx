import type { ReactNode } from "react";
import Link from "@docusaurus/Link";
import useBaseUrl from "@docusaurus/useBaseUrl";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";

const navLinkClass =
  "inline-block py-1 text-sm text-slate-700 underline-offset-2 hover:text-brand hover:underline dark:text-slate-200/90 dark:hover:text-blue-300";
const iconLinkClass =
  "inline-flex items-center gap-1.5 py-1 text-sm text-slate-700 underline-offset-2 hover:text-brand hover:underline dark:text-slate-200/90 dark:hover:text-blue-300";

function GitHubIcon(): ReactNode {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 16 16"
      className="h-4 w-4 shrink-0 fill-current"
    >
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82A7.65 7.65 0 0 1 8 3.86c.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8Z" />
    </svg>
  );
}

export default function Footer(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  const wechatQrSrc = useBaseUrl("/img/wechat_qr.jpg");
  const domesticSite = Boolean(
    (siteConfig.customFields as { domesticSite?: boolean } | undefined)
      ?.domesticSite,
  );

  return (
    <footer className="py-12 lg:py-16 border-t border-slate-200 bg-white text-slate-900 dark:border-slate-700/40 dark:bg-slate-950/90 dark:text-slate-100">
      <div className="mx-auto max-w-[1180px] px-4 pb-4 pt-9">
        <div className="flex flex-col items-start justify-between gap-8 sm:flex-row sm:items-start">
          <div className="max-w-[32ch]">
            <Heading
              as="h3"
              className="m-0 text-[1.1rem] font-semibold tracking-[-0.01em]"
            >
              {siteConfig.title}
            </Heading>
            <p className="mt-2 text-sm leading-relaxed text-slate-600 dark:text-slate-300/90">
              <Translate id="footer.tagline">
                快速、安全的文件传输与分享
              </Translate>
            </p>
          </div>

          <div className="flex shrink-0 flex-col items-center sm:items-end">
            <img
              src={wechatQrSrc}
              alt=""
              width={112}
              height={112}
              className="h-28 w-28 rounded-lg border border-slate-200 bg-white object-cover dark:border-slate-600"
              loading="lazy"
              decoding="async"
            />
            <div className="mt-2 text-sm text-slate-500 w-full text-center">
              <Translate id="footer.wechatOfficial">微信公众号</Translate>
            </div>
          </div>
        </div>

        <nav className="border-t border-slate-200 pt-6 dark:border-slate-700/40">
          <ul className="m-0 flex list-none flex-wrap items-center gap-x-5 gap-y-2 p-0 sm:gap-x-8">
            <li>
              <Link to="/docs/doc/mac-install-damaged" className={navLinkClass}>
                <Translate id="footer.nav.docs">文档</Translate>
              </Link>
            </li>
            <li>
              <Link to="/down" className={navLinkClass}>
                <Translate id="footer.nav.download">下载</Translate>
              </Link>
            </li>
            <li>
              <Link to="/docs/doc/faq" className={navLinkClass}>
                <Translate id="footer.nav.faq">常见问题</Translate>
              </Link>
            </li>
            <li>
              <Link to="/docs/doc/contact-us" className={navLinkClass}>
                <Translate id="footer.nav.contact">联系我们</Translate>
              </Link>
            </li>
            <li>
              <Link to="/privacy" className={navLinkClass}>
                <Translate id="footer.nav.privacy">隐私政策</Translate>
              </Link>
            </li>
            <li>
              <a
                href="https://github.com/bfzg/etedrop"
                target="_blank"
                rel="noreferrer noopener"
                className={iconLinkClass}
              >
                <GitHubIcon />
                <span>GitHub</span>
              </a>
            </li>
          </ul>
        </nav>

        <div className="mt-6 border-t border-slate-200 pt-6 text-sm text-slate-600 dark:border-slate-700/40 dark:text-slate-300/80">
          <div className="flex flex-wrap items-center justify-center gap-x-2 gap-y-1 sm:justify-start">
            <span>
              © {new Date().getFullYear()} {siteConfig.title}
            </span>
            <span aria-hidden="true" className="opacity-60">
              ·
            </span>
            <span className="opacity-90">
              <Translate id="footer.builtWith">Continuously updating</Translate>
            </span>
            {domesticSite ? (
              <>
                <span aria-hidden="true" className="opacity-60">
                  ·
                </span>
                <a
                  href="https://beian.miit.gov.cn/"
                  target="_blank"
                  rel="noreferrer noopener"
                  className="opacity-90 underline-offset-2 hover:text-slate-900 hover:underline dark:hover:text-slate-100">
                  皖ICP备2024066445号-4
                </a>
              </>
            ) : null}
          </div>
        </div>
      </div>
    </footer>
  );
}
