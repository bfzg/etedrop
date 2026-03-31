import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import Translate, {translate} from '@docusaurus/Translate';

type Capability = {
  titleId: string;
  titleDefault: string;
  descId: string;
  descDefault: string;
};

const capabilities: Capability[] = [
  {
    titleId: 'homepage.capability.p2p.title',
    titleDefault: 'P2P 直连传输',
    descId: 'homepage.capability.p2p.desc',
    descDefault: '基于 WebRTC DataChannel，局域网直连更快，公网也可用。',
  },
  {
    titleId: 'homepage.capability.share.title',
    titleDefault: '分享链接与取件码',
    descId: 'homepage.capability.share.desc',
    descDefault: '面向“发给自己 / 发给朋友 / 临时分享”的轻量工作流。',
  },
  {
    titleId: 'homepage.capability.stream.title',
    titleDefault: '流媒体播放增强',
    descId: 'homepage.capability.stream.desc',
    descDefault: 'MSE + fMP4 方案支持进度条、倍速与按需 seek 的体验优化。',
  },
  {
    titleId: 'homepage.capability.cross.title',
    titleDefault: '跨平台体验一致',
    descId: 'homepage.capability.cross.desc',
    descDefault: 'Flutter 客户端 + Web 分享页 + 服务端信令，整体闭环可迭代。',
  },
  {
    titleId: 'homepage.capability.sec.title',
    titleDefault: '安全与可控',
    descId: 'homepage.capability.sec.desc',
    descDefault: '链路可观测、协议可演进，后续可逐步补齐鉴权与可靠性策略。',
  },
  {
    titleId: 'homepage.capability.docs.title',
    titleDefault: '文档即源码',
    descId: 'homepage.capability.docs.desc',
    descDefault: '官网文档直接读取仓库根目录 doc/ 的 Markdown，随代码版本化。',
  },
];

function CapabilityGrid() {
  return (
    <section className="py-12">
      <div className="mx-auto w-full max-w-[1180px] px-4">
        <div className="mb-5 grid gap-1">
          <Heading as="h2" className="m-0 text-[1.75rem] tracking-[-0.01em]">
            <Translate id="homepage.capabilities.title">产品能力</Translate>
          </Heading>
          <p className="m-0 max-w-[68ch] text-slate-600 dark:text-slate-300/90">
            <Translate id="homepage.capabilities.subtitle">
              面向“快速发送”的核心能力集合，兼顾体验与可维护性。
            </Translate>
          </p>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {capabilities.map((c) => (
            <div
              key={c.titleId}
              className="rounded-2xl border border-slate-200 bg-white/80 p-5 shadow-[0_10px_22px_rgba(2,6,23,0.05)] backdrop-blur dark:border-slate-700/40 dark:bg-slate-950/30 dark:shadow-[0_18px_40px_rgba(0,0,0,0.26)]">
              <Heading as="h3" className="m-0 text-[1.05rem] tracking-[-0.01em]">
                <Translate id={c.titleId}>{c.titleDefault}</Translate>
              </Heading>
              <p className="mt-2 text-slate-600 dark:text-slate-300/90">
                <Translate id={c.descId}>{c.descDefault}</Translate>
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function HowItWorks() {
  return (
    <section className="bg-linear-to-b from-white to-slate-50 py-14 dark:from-slate-950/85 dark:to-slate-900/60">
      <div className="mx-auto w-full max-w-[1180px] px-4">
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="grid gap-3">
            <Heading as="h2" className="m-0 text-[1.75rem] tracking-[-0.01em]">
              <Translate id="homepage.howItWorks.title">工作原理</Translate>
            </Heading>
            <p className="m-0 max-w-[68ch] text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.howItWorks.subtitle">
                以 DataChannel 传输为主线：设备在线管理与信令转发由服务端承担，数据尽量走端到端直连。
              </Translate>
            </p>
            <ul className="mt-2 grid list-none gap-3 p-0">
              <li className="grid gap-1 rounded-2xl border border-slate-200 bg-white/70 px-4 py-3.5 dark:border-slate-700/40 dark:bg-slate-950/30">
                <strong>
                  <Translate id="homepage.howItWorks.step1">连接</Translate>
                </strong>
                <span className="text-slate-600 dark:text-slate-300/90">
                  <Translate id="homepage.howItWorks.step1.desc">
                    浏览器通过取件码/分享链接与设备建立会话。
                  </Translate>
                </span>
              </li>
              <li className="grid gap-1 rounded-2xl border border-slate-200 bg-white/70 px-4 py-3.5 dark:border-slate-700/40 dark:bg-slate-950/30">
                <strong>
                  <Translate id="homepage.howItWorks.step2">协商</Translate>
                </strong>
                <span className="text-slate-600 dark:text-slate-300/90">
                  <Translate id="homepage.howItWorks.step2.desc">
                    WebRTC offer/answer/ICE 通过信令通道交换。
                  </Translate>
                </span>
              </li>
              <li className="grid gap-1 rounded-2xl border border-slate-200 bg-white/70 px-4 py-3.5 dark:border-slate-700/40 dark:bg-slate-950/30">
                <strong>
                  <Translate id="homepage.howItWorks.step3">传输</Translate>
                </strong>
                <span className="text-slate-600 dark:text-slate-300/90">
                  <Translate id="homepage.howItWorks.step3.desc">
                    文件/流媒体分片在 DataChannel 中传输，前端按需渲染与播放。
                  </Translate>
                </span>
              </li>
            </ul>
          </div>

          <div aria-hidden="true" className="pt-2">
            <div className="rounded-2xl border border-slate-200 bg-white/75 p-5 shadow-[0_12px_26px_rgba(2,6,23,0.06)] dark:border-slate-700/40 dark:bg-slate-950/30 dark:shadow-[0_18px_40px_rgba(0,0,0,0.28)]">
              <div className="mb-3 grid grid-cols-[auto_1fr_auto] items-center gap-3">
                <div className="inline-flex items-center justify-center rounded-full border border-slate-200 bg-slate-50 px-3 py-2 text-[0.95rem] font-semibold dark:border-slate-700/40 dark:bg-slate-900/40">
                  Web
                </div>
                <div className="h-2.5 rounded-full bg-slate-300/60" />
                <div className="inline-flex items-center justify-center rounded-full border border-slate-200 bg-slate-50 px-3 py-2 text-[0.95rem] font-semibold dark:border-slate-700/40 dark:bg-slate-900/40">
                  Server
                </div>
              </div>
              <div className="grid grid-cols-[auto_1fr_auto] items-center gap-3">
                <div className="inline-flex items-center justify-center rounded-full border border-slate-200 bg-slate-50 px-3 py-2 text-[0.95rem] font-semibold dark:border-slate-700/40 dark:bg-slate-900/40">
                  Web
                </div>
                <div className="h-2.5 rounded-full bg-linear-to-r from-brand/55 to-brand/10 dark:from-blue-400/60 dark:to-blue-400/10" />
                <div className="inline-flex items-center justify-center rounded-full border border-slate-200 bg-slate-50 px-3 py-2 text-[0.95rem] font-semibold dark:border-slate-700/40 dark:bg-slate-900/40">
                  Device
                </div>
              </div>
              <div className="mt-2 text-[0.95rem] text-slate-600 dark:text-slate-300/90">
                <Translate id="homepage.howItWorks.hint">信令走服务端，数据尽量直连</Translate>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function UseCases() {
  const items = [
    {
      id: 'homepage.useCases.1',
      title: '发给自己',
      desc: '电脑与手机互传，临时文件快速到位。',
    },
    {
      id: 'homepage.useCases.2',
      title: '发给朋友',
      desc: '分享链接/取件码更顺手，减少打包与中转。',
    },
    {
      id: 'homepage.useCases.3',
      title: '临时分享',
      desc: '无需把所有内容都上传到云端，按需传输。',
    },
  ] as const;

  return (
    <section className="py-12">
      <div className="mx-auto w-full max-w-[1180px] px-4">
        <div className="mb-5 grid gap-1">
          <Heading as="h2" className="m-0 text-[1.75rem] tracking-[-0.01em]">
            <Translate id="homepage.useCases.title">适用场景</Translate>
          </Heading>
          <p className="m-0 max-w-[68ch] text-slate-600 dark:text-slate-300/90">
            <Translate id="homepage.useCases.subtitle">
              目标不是“又一个网盘”，而是让传输更快、更轻、更可控。
            </Translate>
          </p>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {items.map((it) => (
            <div
              key={it.id}
              className="rounded-2xl border border-slate-200 bg-white/70 p-5 shadow-[0_10px_20px_rgba(2,6,23,0.05)] dark:border-slate-700/40 dark:bg-slate-950/25 dark:shadow-[0_18px_40px_rgba(0,0,0,0.26)]">
              <Heading as="h3" className="m-0 text-[1.05rem] tracking-[-0.01em]">
                <Translate id={`${it.id}.title`}>{it.title}</Translate>
              </Heading>
              <p className="mt-2 text-slate-600 dark:text-slate-300/90">
                <Translate id={`${it.id}.desc`}>{it.desc}</Translate>
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function FAQ() {
  const faqs = [
    {
      id: 'homepage.faq.1',
      q: '是否依赖中心化存储？',
      a: '核心传输尽量走端到端直连；服务端主要负责在线管理与信令转发。',
    },
    {
      id: 'homepage.faq.2',
      q: '公网环境能用吗？',
      a: '支持 STUN/TURN 策略扩展；连接质量与网络环境相关，可按需部署 TURN。',
    },
    {
      id: 'homepage.faq.3',
      q: '为什么支持流媒体？',
      a: '面向大文件/视频场景，MSE + 分片可以带来更好的进度条、倍速与 seek 体验。',
    },
  ] as const;

  return (
    <section className="bg-linear-to-b from-white to-slate-50 py-14 dark:from-slate-950/85 dark:to-slate-900/60">
      <div className="mx-auto w-full max-w-[1180px] px-4">
        <div className="mb-4 grid gap-1">
          <Heading as="h2" className="m-0 text-[1.75rem] tracking-[-0.01em]">
            <Translate id="homepage.faq.title">常见问题</Translate>
          </Heading>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {faqs.map((f) => (
            <div key={f.id} className="rounded-2xl border border-slate-200 bg-white/70 p-5 dark:border-slate-700/40 dark:bg-slate-950/25">
              <Heading as="h3" className="m-0 text-[1.05rem] tracking-[-0.01em]">
                <Translate id={`${f.id}.q`}>{f.q}</Translate>
              </Heading>
              <p className="mt-2 text-slate-600 dark:text-slate-300/90">
                <Translate id={`${f.id}.a`}>{f.a}</Translate>
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function FinalCta() {
  return (
    <section className="py-10 pb-16">
      <div className="mx-auto w-full max-w-[1180px] px-4">
        <div className="flex flex-col items-start justify-between gap-4 rounded-3xl border border-slate-200 bg-[radial-gradient(600px_240px_at_20%_30%,rgba(0,82,217,0.12),transparent_60%),linear-gradient(180deg,rgba(248,250,252,0.92),rgba(255,255,255,0.88))] p-6 shadow-[0_16px_34px_rgba(2,6,23,0.07)] dark:border-slate-700/40 dark:bg-[radial-gradient(700px_280px_at_20%_30%,rgba(79,140,255,0.18),transparent_60%),linear-gradient(180deg,rgba(15,23,42,0.78),rgba(2,6,23,0.64))] dark:shadow-[0_22px_50px_rgba(0,0,0,0.32)] lg:flex-row lg:items-center">
          <div>
            <Heading as="h2" className="m-0 text-[1.75rem] tracking-[-0.01em]">
              <Translate id="homepage.finalCta.title">准备开始了吗？</Translate>
            </Heading>
            <p className="m-0 mt-1 max-w-[68ch] text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.finalCta.subtitle">
                从使用指南开始，把一次传输流程跑通，再按需深入协议与实现细节。
              </Translate>
            </p>
          </div>
          <div className="flex flex-wrap gap-3">
            <Link className="button button--primary button--lg" to="/docs/how-to-use">
              <Translate id="homepage.finalCta.primary">阅读使用指南</Translate>
            </Link>
            <Link className="button button--secondary button--lg" to="/docs">
              <Translate id="homepage.finalCta.secondary">浏览全部文档</Translate>
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}

function Hero() {
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

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={siteConfig.title}
      description={translate({
        id: 'homepage.meta.description',
        message: 'Fast Send 官网：产品能力、使用指南与技术文档。',
      })}>
      <main className="bg-white text-slate-900 dark:bg-slate-950/90 dark:text-slate-100">
        <Hero />
        <CapabilityGrid />
        <HowItWorks />
        <UseCases />
        <FAQ />
        <FinalCta />
      </main>
    </Layout>
  );
}
