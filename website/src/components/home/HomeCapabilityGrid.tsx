import type { ReactNode } from "react";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";
import Container from "../Container";

export default function HomeCapabilityGrid(): ReactNode {
  return (
    <section className="w-full py-12">
      <Container>
        <div className="rounded-2xl border border-slate-200 bg-white/80 p-6 sm:p-8 dark:border-slate-700/40 dark:bg-slate-950/30">
          <Heading as="h2" className="m-0 text-[1.75rem] tracking-[-0.01em]">
            <Translate id="homepage.publicE2e.title">公网端到端传输</Translate>
          </Heading>
          <p className="mt-3 m-0 max-w-[72ch] text-slate-600 dark:text-slate-300/90">
            <Translate id="homepage.publicE2e.lead">
              在公网环境下，数据在发送端与接收端之间直连传输，服务端主要负责会话与信令，文件内容尽量不经过中心化存储中转。
            </Translate>
          </p>
          <ul className="mt-4 mb-0 grid list-disc gap-2 pl-5 text-slate-600 dark:text-slate-300/90 sm:max-w-[72ch]">
            <li>
              <Translate id="homepage.publicE2e.point.play">
                支持 MP4 等视频在线播放，大文件也能边收边看。
              </Translate>
            </li>
            <li>
              <Translate id="homepage.publicE2e.point.download">
                高速下载，直连链路充分利用带宽。
              </Translate>
            </li>
            <li>
              <Translate id="homepage.publicE2e.point.privacy">
                隐私优先：减少不必要的协议外拷贝，分享范围由你掌控。
              </Translate>
            </li>
            <li>
              <Translate id="homepage.publicE2e.point.crypto">
                传输链路可配合加密策略，兼顾安全与性能。
              </Translate>
            </li>
            <li>
              <Translate id="homepage.publicE2e.point.safe">
                安全设计可演进：从会话校验到更细粒度策略可持续加固。
              </Translate>
            </li>
            <li>
              <Translate id="homepage.publicE2e.point.easy">
                使用方式简单：分享链接或取件码即可开始传输。
              </Translate>
            </li>
          </ul>
        </div>
      </Container>
    </section>
  );
}
