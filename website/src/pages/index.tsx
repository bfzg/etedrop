import type {ReactNode} from 'react';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import {translate} from '@docusaurus/Translate';
import {
  HomeHero,
  HomeCapabilityGrid,
  HomeHowItWorks,
  HomeUseCases,
  HomeFaq,
  HomeFinalCta,
} from '@site/src/components/home';

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={siteConfig.title}
      description={translate({
        id: 'homepage.meta.description',
        message: 'Fast Send 官网：产品能力、使用指南与技术文档。',
      })}>
      <main className="bg-white text-slate-900 dark:bg-slate-950/90 dark:text-slate-100">
        <HomeHero />
        <HomeCapabilityGrid />
        <HomeHowItWorks />
        <HomeUseCases />
        <HomeFaq />
        <HomeFinalCta />
      </main>
    </Layout>
  );
}
