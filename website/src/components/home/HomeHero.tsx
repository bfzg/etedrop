import type { ReactNode } from "react";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";
import { Button, ButtonLink } from "@site/src/components/ui/Button";
import Container from "../Container";

export default function HomeHero(): ReactNode {
  return (
    <header
      className="relative overflow-hidden pb-14 pt-48"
    >
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0"
        style={{
          backgroundImage:
            "radial-gradient(circle at 1px 1px, rgba(15, 23, 42, 0.28) 1px, transparent 0)",
          backgroundSize: "15px 15px",
          backgroundPositionX: "7.5px",
          backgroundPositionY: "7.5px",
          opacity: 0.4,
        }}
      />

      <Container className="relative z-10 flex flex-col items-center justify-center space-y-8">
        <Heading
          as="h1"
          className="m-0 text-[clamp(2.6rem,3.6vw,3.4rem)] leading-[1.05] tracking-[-0.02em]"
        >
          <Translate id="homepage.hero.title">把文件发送给任何人</Translate>
        </Heading>
        <p className="m-0 text-[1.15rem] leading-relaxed text-slate-600 dark:text-slate-300/90">
          <Translate id="homepage.hero.subtitle">
            以 p2p 为核心的快速传输方案：分享、播放、文档，一站式闭环。
          </Translate>
        </p>

        <div className="flex flex-wrap items-center gap-3 pt-2">
          <Button className="w-56 h-14 text-xl" variant="primary">
            <Translate id="homepage.hero.primaryCta">立即下载</Translate>
          </Button>
        </div>
      </Container>
    </header>
  );
}
