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
          <div className="lg:order-2">
            <div className="text-3xl font-medium">
              <Translate id="homepage.lanNotify.title">消息提示</Translate>
            </div>
            <p className="pt-1 max-w-[68ch] text-slate-600">
              <Translate id="homepage.lanNotify.subtitle">
                系统级消息提示，应用内查看，一键接收消息。
              </Translate>
            </p>
            <ul className="pt-5 grid list-disc gap-2 pl-5 text-lg text-slate-600">
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
          <div className="rounded-2xl border border-slate-200 bg-white/80 p-3 lg:order-1">
            <video
              className="block w-full rounded-xl border border-slate-200/80"
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
