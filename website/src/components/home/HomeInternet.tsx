import type { ReactNode } from "react";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";
import Container from "../Container";
import E2eTriangleDiagram from "./E2eTriangleDiagram";

const features = [
  {
    id: "play",
    title: "Mp4 播放",
    text: "支持 MP4 等视频在线播放，大文件也能边收边看。",
  },
  {
    id: "download",
    title: "高速下载",
    text: "p2p 高速下载，直连链路充分利用带宽。",
  },
  {
    id: "privacy",
    title: "隐私优先",
    text: "数据不会经过服务器，真正的P2P传输。",
  },
  {
    id: "efficiency",
    title: "效率提升",
    text: "无需上传到云端，P2P传输，节省50%的传输时间。",
  },
  {
    id: "easy",
    title: "操作简单",
    text: "浏览器点击直接下载，无需安装客户端。",
  },
  {
    id: "lan",
    title: "局域网传输",
    text: "同网络下设备互传，超快速度无延迟。",
  },
];

export default function HomeInternet(): ReactNode {
  return (
    <section className="w-full py-16">
      <Container>
        {/* 头部标题与描述 */}
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

        {/* 虚线边框卡片网格 */}
        <div className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <div
              key={feature.id}
              className="flex h-full flex-col justify-center rounded-2xl border-2 border-dashed border-slate-300 px-4 py-3 transition-all duration-300 hover:border-blue-500 hover:bg-slate-50 dark:border-slate-700 dark:hover:border-blue-400 dark:hover:bg-slate-800/50"
            >
              <div className="text-lg font-medium pb-1.5">{feature.title}</div>

              <p className="m-0 text-sm leading-relaxed text-slate-700 dark:text-slate-200">
                <Translate id={`homepage.publicE2e.point.${feature.id}`}>
                  {feature.text}
                </Translate>
              </p>
            </div>
          ))}
        </div>

        <div className="hidden lg:block">
          <E2eTriangleDiagram />
        </div>
      </Container>
    </section>
  );
}
