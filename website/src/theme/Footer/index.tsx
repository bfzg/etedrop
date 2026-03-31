import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Heading from '@theme/Heading';
import Translate from '@docusaurus/Translate';

export default function Footer(): ReactNode {
  const {siteConfig} = useDocusaurusContext();

  return (
    <footer className="border-t border-slate-200 bg-white text-slate-900 dark:border-slate-700/40 dark:bg-slate-950/90 dark:text-slate-100">
      <div className="mx-auto max-w-[1180px] px-4 pb-5 pt-9">
        <div className="flex flex-col items-start justify-between gap-9 lg:flex-row">
          <div className="max-w-[32ch]">
            <Heading as="h3" className="m-0 text-[1.1rem] font-semibold tracking-[-0.01em]">
              {siteConfig.title}
            </Heading>
            <p className="mt-2 text-sm leading-relaxed text-slate-600 dark:text-slate-300/90">
              <Translate id="footer.tagline">快速、安全的文件传输与分享</Translate>
            </p>
          </div>

          <div className="grid w-full grid-cols-1 gap-8 sm:grid-cols-2 lg:w-auto lg:grid-cols-3">
            <div>
              <div className="mb-2 text-sm font-semibold text-slate-900/90 dark:text-slate-100/90">
                <Translate id="footer.col.product">产品</Translate>
              </div>
              <Link className="block py-1.5 text-sm text-slate-700 hover:text-brand dark:text-slate-200/90 dark:hover:text-blue-300" to="/">
                <Translate id="footer.link.home">首页</Translate>
              </Link>
              <Link
                className="block py-1.5 text-sm text-slate-700 hover:text-brand dark:text-slate-200/90 dark:hover:text-blue-300"
                to="/docs/how-to-use">
                <Translate id="footer.link.howToUse">使用指南</Translate>
              </Link>
            </div>

            <div>
              <div className="mb-2 text-sm font-semibold text-slate-900/90 dark:text-slate-100/90">
                <Translate id="footer.col.docs">文档</Translate>
              </div>
              <Link className="block py-1.5 text-sm text-slate-700 hover:text-brand dark:text-slate-200/90 dark:hover:text-blue-300" to="/docs">
                <Translate id="footer.link.docs">文档首页</Translate>
              </Link>
              <Link
                className="block py-1.5 text-sm text-slate-700 hover:text-brand dark:text-slate-200/90 dark:hover:text-blue-300"
                to="/docs/服务端架构总览">
                <Translate id="footer.link.serverArch">服务端架构</Translate>
              </Link>
              <Link
                className="block py-1.5 text-sm text-slate-700 hover:text-brand dark:text-slate-200/90 dark:hover:text-blue-300"
                to="/docs/信令协议说明">
                <Translate id="footer.link.signaling">信令协议</Translate>
              </Link>
            </div>

            <div>
              <div className="mb-2 text-sm font-semibold text-slate-900/90 dark:text-slate-100/90">
                <Translate id="footer.col.more">更多</Translate>
              </div>
              <Link className="block py-1.5 text-sm text-slate-700 hover:text-brand dark:text-slate-200/90 dark:hover:text-blue-300" to="/blog">
                <Translate id="footer.link.blog">文章</Translate>
              </Link>
              <a
                className="block py-1.5 text-sm text-slate-700 hover:text-brand dark:text-slate-200/90 dark:hover:text-blue-300"
                href="https://github.com/"
                target="_blank"
                rel="noreferrer">
                <Translate id="footer.link.github">GitHub</Translate>
              </a>
            </div>
          </div>
        </div>

        <div className="mt-6 flex items-center gap-2 border-t border-slate-200 pt-4 text-sm text-slate-600 dark:border-slate-700/40 dark:text-slate-300/80">
          <span>
            © {new Date().getFullYear()} {siteConfig.title}
          </span>
          <span aria-hidden="true" className="opacity-60">
            ·
          </span>
          <span className="opacity-90">
            <Translate id="footer.builtWith">Built with Docusaurus</Translate>
          </span>
        </div>
      </div>
    </footer>
  );
}

