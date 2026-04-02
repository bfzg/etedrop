import type { ReactNode } from "react";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";
import { ButtonLink } from "@site/src/components/ui/Button";
import Container from "../Container";

export default function HomeHero(): ReactNode {
  return (
    <header className="relative overflow-hidden pb-14 pt-20">
      <Container className="flex flex-col items-center justify-center space-y-8">
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
          <ButtonLink size="lg" to="/docs/how-to-use" variant="primary">
            <Translate id="homepage.hero.primaryCta">开始使用</Translate>
          </ButtonLink>
          <ButtonLink size="lg" to="/docs" variant="default">
            <Translate id="homepage.hero.secondaryCta">查看文档</Translate>
          </ButtonLink>
        </div>
      </Container>
    </header>
  );
}
