import type { ReactNode } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";
import Container from "../Container";

export default function HomeLanNotify(): ReactNode {
  const videoSrc = useBaseUrl("/video/notify_video.mp4");

  return (
    <section className="w-full py-12">
      <Container>
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-2 lg:items-center">
          <div className="grid gap-3 lg:order-2">
            <Heading as="h2" className="m-0 text-[1.75rem] tracking-[-0.01em]">
              <Translate id="homepage.lanNotify.title">局域网消息提示</Translate>
            </Heading>
            <p className="m-0 max-w-[68ch] text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.lanNotify.subtitle">
                接收端可收到系统级通知，无需一直停留在页面也能掌握传输进度与结果。
              </Translate>
            </p>
            <ul className="m-0 grid list-disc gap-2 pl-5 text-slate-600 dark:text-slate-300/90">
              <li>
                <Translate id="homepage.lanNotify.p1">
                  系统级消息提示：新任务、完成与异常状态更易感知。
                </Translate>
              </li>
              <li>
                <Translate id="homepage.lanNotify.p2">
                  接收状态一目了然：进行中、已成功或失败均有反馈。
                </Translate>
              </li>
            </ul>
          </div>
          <div className="rounded-2xl border border-slate-200 bg-white/80 p-3 lg:order-1 dark:border-slate-700/40 dark:bg-slate-950/30">
            <video
              className="block w-full rounded-xl border border-slate-200/80 dark:border-slate-700/50"
              src={videoSrc}
              autoPlay
              muted
              loop
              playsInline
              preload="metadata"
            />
          </div>
        </div>
      </Container>
    </section>
  );
}
