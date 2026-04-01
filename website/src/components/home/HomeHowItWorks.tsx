import type {ReactNode} from 'react';
import Heading from '@theme/Heading';
import Translate from '@docusaurus/Translate';

export default function HomeHowItWorks(): ReactNode {
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
