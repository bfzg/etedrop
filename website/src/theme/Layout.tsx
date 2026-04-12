import type { ReactNode } from "react";
import type { Props } from "@theme/Layout";
import OriginalLayout from "@theme-original/Layout";
// cn 镜像站未备案期间关闭「按访问启发式引导至 cn 域名」横幅；恢复时取消下行与下方 <CnMirrorBanner /> 注释。
// import CnMirrorBanner from "@site/src/components/CnMirrorBanner";

export default function Layout(props: Props): ReactNode {
  const { children } = props;
  return (
    <OriginalLayout {...props}>
      {/* <CnMirrorBanner /> */}
      {children}
    </OriginalLayout>
  );
}
