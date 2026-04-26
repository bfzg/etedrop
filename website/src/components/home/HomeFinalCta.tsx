import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import Heading from '@theme/Heading';
import Translate from '@docusaurus/Translate';
import Container from '../Container';

export default function HomeFinalCta(): ReactNode {
  return (
    <section className="py-10 pb-16">
      <Container>
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
            <Link className="button button--primary button--lg" to="/docs/doc/mac-install-damaged">
              <Translate id="homepage.finalCta.primary">阅读使用指南</Translate>
            </Link>
            <Link className="button button--secondary button--lg" to="/docs/doc/mac-install-damaged">
              <Translate id="homepage.finalCta.secondary">浏览全部文档</Translate>
            </Link>
          </div>
        </div>
      </Container>
    </section>
  );
}
