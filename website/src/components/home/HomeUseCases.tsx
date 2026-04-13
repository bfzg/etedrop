import type { ReactNode } from "react";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";
import Container from "../Container";

export default function HomeUseCases(): ReactNode {
  return (
      <Container>
        <div className="mb-10 grid gap-1 md:mb-12">
          <div className="text-4xl font-medium text-center">
            <Translate id="homepage.useCases.title">适用场景</Translate>
          </div>
          <p className="pt-2 text-center text-slate-600">
            <Translate id="homepage.useCases.subtitle">
              目标不是“又一个网盘”，而是让传输更快、更轻、更可控。
            </Translate>
          </p>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div className="rounded-2xl border-2 border-dashed border-slate-200 px-5 pt-3">
            <Heading as="h3" className="m-0 text-[1.05rem] tracking-[-0.01em]">
              <Translate id="homepage.useCases.1.title">发给自己</Translate>
            </Heading>
            <p className="mt-2 text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.useCases.1.desc">
                电脑与手机互传，临时文件快速到位。
              </Translate>
            </p>
          </div>
          <div className="rounded-2xl border-2 border-dashed border-slate-200 px-5 pt-3">
            <Heading as="h3" className="m-0 text-[1.05rem] tracking-[-0.01em]">
              <Translate id="homepage.useCases.2.title">发给朋友</Translate>
            </Heading>
            <p className="mt-2 text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.useCases.2.desc">
                分享链接/取件码更顺手，减少打包与中转。
              </Translate>
            </p>
          </div>
          <div className="rounded-2xl border-2 border-dashed border-slate-200 px-5 pt-3">
            <Heading as="h3" className="m-0 text-[1.05rem] tracking-[-0.01em]">
              <Translate id="homepage.useCases.3.title">临时分享</Translate>
            </Heading>
            <p className="mt-2 text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.useCases.3.desc">
                无需把所有内容都上传到云端，按需传输。
              </Translate>
            </p>
          </div>
          <div className="rounded-2xl border-2 border-dashed border-slate-200 px-5 pt-3">
            <Heading as="h3" className="m-0 text-[1.05rem] tracking-[-0.01em]">
              <Translate id="homepage.useCases.4.title">办公室互传</Translate>
            </Heading>
            <p className="mt-2 text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.useCases.4.desc">
                可以将文件同时发送给多个人。极大提升办公效率。
              </Translate>
            </p>
          </div>
          <div className="rounded-2xl border-2 border-dashed border-slate-200 px-5 pt-3">
            <Heading as="h3" className="m-0 text-[1.05rem] tracking-[-0.01em]">
              <Translate id="homepage.useCases.5.title">异地预览</Translate>
            </Heading>
            <p className="mt-2 text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.useCases.5.desc">
                PDF、图片、音视频与文本等在浏览器中预览；MP4 可边收边看。
              </Translate>
            </p>
          </div>
          <div className="rounded-2xl border-2 border-dashed border-slate-200 px-5 pt-3">
            <Heading as="h3" className="m-0 text-[1.05rem] tracking-[-0.01em]">
              <Translate id="homepage.useCases.6.title">多设备同步</Translate>
            </Heading>
            <p className="mt-2 text-slate-600 dark:text-slate-300/90">
              <Translate id="homepage.useCases.6.desc">
                多台设备直接互相发送（后续支持多设备文件同步）
              </Translate>
            </p>
          </div>
        </div>
      </Container>
  );
}
