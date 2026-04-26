import type { ReactNode } from "react";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import { translate } from "@docusaurus/Translate";
import {
  HomeHero,
  HomeOnlinePreview,
  HomeCapabilityGrid,
  HomeLanTransfer,
  HomeLanNotify,
  HomeUseCases,
  HomeFaq,
} from "@site/src/components/home";
import { PageMetadata } from "@docusaurus/theme-common";
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
      <PageMetadata
        title={translate({
          id: "homepage.seo.title",
          message: "EteDrop-快速、安全的文件传输与分享",
        })}
        description={translate({
          id: "homepage.seo.description",
          message:
            "EteDrop-快速、安全的文件传输与分享。隐私文件传输工具，支持公网、局域网、内网传输。",
        })}
        keywords={translate({
          id: "homepage.seo.keywords",
          message:
            "EteDrop,文件传输,电脑互传文件,局域网互传文件,公网传输文件,文件传输与分享,大文件传输,文件传输工具,文件传输软件,文件传输服务,文件传输解决方案,隐私文件传输,隐私文件传输工具,隐私文件传输软件",
        })}
      />
      <main className="home text-slate-900">
        <HomeHero />
        <HomeCapabilityGrid />
        <HomeLanTransfer />
        <HomeLanNotify />
        <HomeOnlinePreview />
        <HomeUseCases />
        <HomeFaq />
      </main>
      <Footer />
    </Layout>
  );
}
