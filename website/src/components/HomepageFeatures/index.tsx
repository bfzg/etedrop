import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: '跨端传输',
    Svg: require('@site/static/img/undraw_docusaurus_mountain.svg').default,
    description: (
      <>
        Flutter 客户端 + Web 分享页 + 服务端信令，打通局域网/公网文件传输与分享流程。
      </>
    ),
  },
  {
    title: '分享与取件码',
    Svg: require('@site/static/img/undraw_docusaurus_tree.svg').default,
    description: (
      <>
        支持分享链接与取件码连接，面向“发给自己 / 发给朋友 / 临时分享”更顺手。
      </>
    ),
  },
  {
    title: '可维护的文档',
    Svg: require('@site/static/img/undraw_docusaurus_react.svg').default,
    description: (
      <>
        官网文档直接读取仓库根目录 <code>doc/</code> 的 Markdown，和代码一起版本化维护。
      </>
    ),
  },
];

function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className="h-[200px] w-[200px]" role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className="flex w-full items-center py-8">
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
