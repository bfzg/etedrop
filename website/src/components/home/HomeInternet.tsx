import type { ReactNode } from "react";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";
import Container from "../Container";
import E2eTriangleDiagram from "./E2eTriangleDiagram";

export default function HomeInternet(): ReactNode {
  return (
    <section className="w-full py-16">
      <Container>
        <div className="mx-auto max-w-3xl text-center">
          <Heading as="h2" className="text-4xl font-bold">
            <Translate id="homepage.publicE2e.title">我的优势</Translate>
          </Heading>
          <p className="mt-6 text-base font-normal leading-relaxed text-slate-600 dark:text-slate-300/90">
            <Translate id="homepage.publicE2e.lead">
              支持公网环境，数据在发送端与接收端之间直连传输，服务端主要负责会话与信令。
            </Translate>
          </p>
        </div>

        <div className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          <div className="flex h-full flex-col justify-center rounded-2xl border-2 border-dashed border-slate-300 px-4 py-3 transition-all duration-300 hover:border-blue-500 hover:bg-slate-50 dark:border-slate-700 dark:hover:border-blue-400 dark:hover:bg-slate-800/50">
            <div className="pb-1.5 text-lg font-medium">
              <Translate id="homepage.publicE2e.feature.play.title">Mp4 播放</Translate>
            </div>
            <p className="m-0 text-sm leading-relaxed text-slate-700 dark:text-slate-200">
              <Translate id="homepage.publicE2e.feature.play.text">
                支持 MP4 等视频在线播放，大文件也能边收边看。
              </Translate>
            </p>
          </div>
          <div className="flex h-full flex-col justify-center rounded-2xl border-2 border-dashed border-slate-300 px-4 py-3 transition-all duration-300 hover:border-blue-500 hover:bg-slate-50 dark:border-slate-700 dark:hover:border-blue-400 dark:hover:bg-slate-800/50">
            <div className="pb-1.5 text-lg font-medium">
              <Translate id="homepage.publicE2e.feature.download.title">高速下载</Translate>
            </div>
            <p className="m-0 text-sm leading-relaxed text-slate-700 dark:text-slate-200">
              <Translate id="homepage.publicE2e.feature.download.text">
                p2p 高速下载，直连链路充分利用带宽。
              </Translate>
            </p>
          </div>
          <div className="flex h-full flex-col justify-center rounded-2xl border-2 border-dashed border-slate-300 px-4 py-3 transition-all duration-300 hover:border-blue-500 hover:bg-slate-50 dark:border-slate-700 dark:hover:border-blue-400 dark:hover:bg-slate-800/50">
            <div className="pb-1.5 text-lg font-medium">
              <Translate id="homepage.publicE2e.feature.privacy.title">隐私优先</Translate>
            </div>
            <p className="m-0 text-sm leading-relaxed text-slate-700 dark:text-slate-200">
              <Translate id="homepage.publicE2e.feature.privacy.text">
                数据不会经过服务器，真正的P2P传输。
              </Translate>
            </p>
          </div>
          <div className="flex h-full flex-col justify-center rounded-2xl border-2 border-dashed border-slate-300 px-4 py-3 transition-all duration-300 hover:border-blue-500 hover:bg-slate-50 dark:border-slate-700 dark:hover:border-blue-400 dark:hover:bg-slate-800/50">
            <div className="pb-1.5 text-lg font-medium">
              <Translate id="homepage.publicE2e.feature.efficiency.title">效率提升</Translate>
            </div>
            <p className="m-0 text-sm leading-relaxed text-slate-700 dark:text-slate-200">
              <Translate id="homepage.publicE2e.feature.efficiency.text">
                无需上传到云端，P2P传输，节省50%的传输时间。
              </Translate>
            </p>
          </div>
          <div className="flex h-full flex-col justify-center rounded-2xl border-2 border-dashed border-slate-300 px-4 py-3 transition-all duration-300 hover:border-blue-500 hover:bg-slate-50 dark:border-slate-700 dark:hover:border-blue-400 dark:hover:bg-slate-800/50">
            <div className="pb-1.5 text-lg font-medium">
              <Translate id="homepage.publicE2e.feature.easy.title">操作简单</Translate>
            </div>
            <p className="m-0 text-sm leading-relaxed text-slate-700 dark:text-slate-200">
              <Translate id="homepage.publicE2e.feature.easy.text">
                浏览器点击直接下载，无需安装客户端。
              </Translate>
            </p>
          </div>
          <div className="flex h-full flex-col justify-center rounded-2xl border-2 border-dashed border-slate-300 px-4 py-3 transition-all duration-300 hover:border-blue-500 hover:bg-slate-50 dark:border-slate-700 dark:hover:border-blue-400 dark:hover:bg-slate-800/50">
            <div className="pb-1.5 text-lg font-medium">
              <Translate id="homepage.publicE2e.feature.lan.title">局域网传输</Translate>
            </div>
            <p className="m-0 text-sm leading-relaxed text-slate-700 dark:text-slate-200">
              <Translate id="homepage.publicE2e.feature.lan.text">
                同网络下设备互传，超快速度无延迟。
              </Translate>
            </p>
          </div>
        </div>

        <div className="hidden lg:block">
          <E2eTriangleDiagram />
        </div>
      </Container>
    </section>
  );
}
