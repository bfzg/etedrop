import type { ReactNode } from "react";
import type { Props } from "@theme/Layout";
import OriginalLayout from "@theme-original/Layout";
import CnMirrorBanner from "@site/src/components/CnMirrorBanner";

export default function Layout(props: Props): ReactNode {
  const { children } = props;
  return (
    <OriginalLayout {...props}>
      <CnMirrorBanner />
      {children}
    </OriginalLayout>
  );
}
