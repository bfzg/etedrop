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
import { PageMetadata } from "@docusaurus/theme-common";
import Footer from "../components/Footer";
import { SEO_DESCRIPTION, SEO_KEYWORDS, SEO_TITLE } from "../constant";

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
      <PageMetadata
        title={SEO_TITLE}
        description={SEO_DESCRIPTION}
        keywords={SEO_KEYWORDS}
      />
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
