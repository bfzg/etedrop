import type { ReactNode } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";
import Container from "../Container";

export default function HomeLanTransfer(): ReactNode {
  const videoSrc = useBaseUrl("/video/lan_video.mp4");

  return (
    <section className="w-full py-12">
      <Container>
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-2 lg:items-center">
          <div className="grid gap-3">
            <Heading as="h2" className="m-0 text-[1.75rem] tracking-[-0.01em]">
              <Translate id="homepage.lanTransfer.title">局域网传输</Translate>
            </Heading>
            <p className="m-0 max-w-[68ch] text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.lanTransfer.subtitle">
                同一局域网内设备直连，适合办公室、家里或机房内大批量、高频率互传。
              </Translate>
            </p>
            <ul className="m-0 grid list-disc gap-2 pl-5 text-slate-600 dark:text-slate-300/90">
              <li>
                <Translate id="homepage.lanTransfer.p1">
                  传输速度更快，链路与拓扑简单时体验更稳定。
                </Translate>
              </li>
              <li>
                <Translate id="homepage.lanTransfer.p2">
                  支持多种文件格式，文档、压缩包、音视频皆可。
                </Translate>
              </li>
              <li>
                <Translate id="homepage.lanTransfer.p3">
                  操作简单、路径短：选中即可发送，支持批量发送。
                </Translate>
              </li>
            </ul>
            <p className="m-0 rounded-xl border border-amber-200/80 bg-amber-50/80 px-4 py-3 text-[0.95rem] text-amber-950 dark:border-amber-500/25 dark:bg-amber-500/10 dark:text-amber-100/95">
              <Translate id="homepage.lanTransfer.browserNote">
                提示：实际可达到的最大传输速度会受浏览器实现、操作系统与硬件性能等因素影响，由浏览器与运行环境共同决定上限。
              </Translate>
            </p>
          </div>
          <div className="rounded-2xl border border-slate-200 bg-white/80 p-3 dark:border-slate-700/40 dark:bg-slate-950/30">
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
