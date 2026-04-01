import type {ReactNode} from 'react';
import Heading from '@theme/Heading';
import Translate from '@docusaurus/Translate';
import Container from '../Container';

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

export default function HomeUseCases(): ReactNode {
  return (
    <section className="py-12">
      <Container>
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
      </Container>
    </section>
  );
}
