import type {ReactNode} from 'react';
import Heading from '@theme/Heading';
import Translate from '@docusaurus/Translate';

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

export default function HomeCapabilityGrid(): ReactNode {
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
