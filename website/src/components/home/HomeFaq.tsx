import type {ReactNode} from 'react';
import Heading from '@theme/Heading';
import Translate from '@docusaurus/Translate';

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

export default function HomeFaq(): ReactNode {
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
