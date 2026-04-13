import type { ReactNode } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import Translate from "@docusaurus/Translate";
import Container from "../Container";

type PreviewItemProps = {
  icon: string;
  titleId: string;
  titleDefault: string;
};

function PreviewItem({
  icon,
  titleId,
  titleDefault,
}: PreviewItemProps): ReactNode {
  const iconSrc = useBaseUrl(`/svg/${icon}`);
  return (
    <div className="group flex flex-col items-center text-center">
      <div className="flex h-20 w-20 items-center justify-center">
        <img
          src={iconSrc}
          alt=""
          className="h-12 w-12 transition-transform duration-300 group-hover:scale-110"
          width={48}
          height={48}
          loading="lazy"
        />
      </div>
      <div className="mb-3 text-lg font-medium">
        <Translate id={titleId}>{titleDefault}</Translate>
      </div>
    </div>
  );
}

export default function HomeOnlinePreview(): ReactNode {
  return (
    <Container>
      <div className="mx-auto max-w-3xl text-center">
        <div className="text-4xl font-medium text-center">
          <Translate id="homepage.preview.title">在线预览</Translate>
        </div>
        <p className="pt-2 text-center text-slate-600">
          <Translate id="homepage.preview.lead">
            直接在浏览器中预览，无需安装客户端即可预览常见格式；
          </Translate>
        </p>
      </div>

      <div className="mt-20 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <PreviewItem
          icon="pdf-file.svg"
          titleId="homepage.preview.pdf.title"
          titleDefault="PDF 文档"
        />
        <PreviewItem
          icon="image-file.svg"
          titleId="homepage.preview.image.title"
          titleDefault="图片预览"
        />
        <PreviewItem
          icon="video-file.svg"
          titleId="homepage.preview.video.title"
          titleDefault="视频播放"
        />
        <PreviewItem
          icon="music.svg"
          titleId="homepage.preview.audio.title"
          titleDefault="音频试听"
        />
        <PreviewItem
          icon="txt-file.svg"
          titleId="homepage.preview.text.title"
          titleDefault="文本代码"
        />
      </div>
    </Container>
  );
}
