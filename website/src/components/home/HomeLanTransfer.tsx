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
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-2 items-center">
          <div>
            <div className="text-3xl font-medium">
              <Translate id="homepage.lanTransfer.title">局域网传输</Translate>
            </div>
            <p className="pt-1 max-w-[68ch] text-slate-600">
              <Translate id="homepage.lanTransfer.subtitle">
                同一局域网内设备直连，适合办公室、多设备互联。
              </Translate>
            </p>
            <ul className="pt-5 grid list-disc gap-2 pl-5 text-lg text-slate-600">
              <li>
                <Translate id="homepage.lanTransfer.p1">
                  传输速度更快，设备快速上线，自定义头像、名称。
                </Translate>
              </li>
              <li>
                <Translate id="homepage.lanTransfer.p2">
                  支持文件，文字，剪切板图片等。批量发送文件，批量接收文件。
                </Translate>
              </li>
              <li>
                <Translate id="homepage.lanTransfer.p3">
                  操作简单、支持批量发送。
                </Translate>
              </li>
            </ul>
          </div>
          <div className="rounded-2xl border border-slate-200 bg-white/80 ">
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
