import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import Heading from '@theme/Heading';
import Translate from '@docusaurus/Translate';

export default function HomeHero(): ReactNode {
  return (
    <header className="relative overflow-hidden pb-14 pt-20">
      <div className="pointer-events-none absolute inset-[-20%]" aria-hidden="true">
        <div className="absolute inset-0 bg-[radial-gradient(900px_520px_at_40%_75%,rgba(15,23,42,0.06),transparent_60%)] dark:bg-[radial-gradient(1000px_600px_at_40%_75%,rgba(148,163,184,0.10),transparent_60%)]" />
        <svg
          className="absolute left-[6%] top-[6%] h-[520px] w-[520px] fill-brand/20 opacity-90 origin-[50%_50%] animate-[floatA_16s_ease-in-out_infinite] dark:fill-blue-400/30 dark:opacity-85"
          viewBox="0 0 600 600"
          xmlns="http://www.w3.org/2000/svg">
          <path d="M421.4,79.4C470.3,112.6,512.8,176,512.6,244.1C512.5,312.3,469.6,385.2,411.5,437.7C353.5,490.2,280.2,522.2,214.1,503C148,483.8,89.1,413.4,74.3,340.1C59.5,266.8,88.7,190.5,139.7,141.6C190.8,92.7,263.7,71.3,332.7,65.5C401.7,59.7,466.6,69.2,421.4,79.4Z" />
        </svg>
        <svg
          className="absolute right-[4%] top-[12%] h-[560px] w-[560px] fill-brand/15 opacity-90 origin-[50%_50%] animate-[floatB_20s_ease-in-out_infinite] dark:fill-blue-400/20 dark:opacity-75"
          viewBox="0 0 600 600"
          xmlns="http://www.w3.org/2000/svg">
          <path d="M438.4,124.5C485.8,165.3,519.7,240.4,503.2,307.4C486.7,374.3,419.8,433.1,348.2,463.6C276.5,494.1,200.1,496.3,142.5,460.4C84.9,424.6,46.1,350.8,52.3,282.6C58.5,214.5,109.8,152,172.2,115.9C234.7,79.8,308.3,70.1,371.7,81.6C435.2,93.2,488.5,126,438.4,124.5Z" />
        </svg>
      </div>
      <div className="mx-auto w-full max-w-[1180px] px-4">
        <div className="relative grid max-w-[720px] gap-5">
          <div className="inline-flex w-fit items-center gap-2 rounded-full border border-slate-300/60 bg-white/65 px-3 py-1.5 text-sm text-slate-600 backdrop-blur dark:border-slate-500/30 dark:bg-slate-950/40 dark:text-slate-300/90">
            <span className="h-2 w-2 rounded-full bg-brand shadow-[0_0_0_6px_rgba(0,82,217,0.12)] dark:bg-blue-400 dark:shadow-[0_0_0_6px_rgba(79,140,255,0.14)]" aria-hidden="true" />
            <Translate id="homepage.hero.badge">跨端文件传输与分享</Translate>
          </div>

          <Heading as="h1" className="m-0 text-[clamp(2.6rem,3.6vw,3.4rem)] leading-[1.05] tracking-[-0.02em]">
            <Translate id="homepage.hero.title">Fast Send</Translate>
          </Heading>
          <p className="m-0 text-[1.15rem] leading-relaxed text-slate-600 dark:text-slate-300/90">
            <Translate id="homepage.hero.subtitle">
              以 WebRTC 为核心的快速传输方案：分享、取件、播放、文档，一站式闭环。
            </Translate>
          </p>

          <div className="flex flex-wrap items-center gap-3 pt-2">
            <Link className="button button--primary button--lg" to="/docs/how-to-use">
              <Translate id="homepage.hero.primaryCta">开始使用</Translate>
            </Link>
            <Link
              className="inline-flex items-center gap-1.5 rounded-2xl border border-slate-300/60 bg-white/55 px-4 py-2.5 text-slate-900 no-underline hover:-translate-y-px hover:no-underline dark:border-slate-500/30 dark:bg-slate-950/35 dark:text-slate-100"
              to="/docs">
              <Translate id="homepage.hero.secondaryCta">查看文档</Translate>
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
}
