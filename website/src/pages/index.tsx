import type { ReactNode } from "react";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import { translate } from "@docusaurus/Translate";
import {
  HomeHero,
  HomeCapabilityGrid,
  HomeLanTransfer,
  HomeLanNotify,
  HomeUseCases,
  HomeFaq,
} from "@site/src/components/home";
import Footer from "../components/Footer";

export default function Home(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={siteConfig.title}
      description={translate({
        id: "homepage.meta.description",
        message: "Fast Send 官网：产品能力、使用指南与技术文档。",
      })}
    >
      <main className="home text-slate-900">
        <HomeHero />
        <HomeCapabilityGrid />
        <HomeLanTransfer />
        <HomeLanNotify />
        <HomeUseCases />
        <HomeFaq />
        {/* <HomeFinalCta /> */}
      </main>
      <Footer />
    </Layout>
  );
}
