import type { ReactNode } from "react";
import { useMemo } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import Translate from "@docusaurus/Translate";
import { ButtonLink } from "@site/src/components/ui/Button";
import {
  useClientDownloadPlatform,
  useReleaseManifest,
  useResolvedDownloadHref,
} from "../../hooks/useReleaseManifest";
import Container from "../Container";

export default function HomeHero(): ReactNode {
  const shareVideoSrc = useBaseUrl("/video/share_video.mp4");
  const platform = useClientDownloadPlatform();
  const manifest = useReleaseManifest();
  const macIcon = useBaseUrl("/svg/mac-icon.svg");
  const winIcon = useBaseUrl("/svg/windows-icon.svg");
  const winHref = useResolvedDownloadHref(manifest.windowsDownloadUrl);
  const macHref = useResolvedDownloadHref(manifest.macDownloadUrl);

  const primaryCta = useMemo(() => {
    if (platform === "macos") {
      return {
        to: macHref,
        icon: macIcon,
        download: true,
      } as const;
    }
    if (platform === "windows") {
      return {
        to: winHref,
        icon: winIcon,
        download: true,
      } as const;
    }
    return {
      to: "/down",
      icon: null as string | null,
      download: undefined,
    } as const;
  }, [platform, macHref, winHref, macIcon, winIcon]);

  return (
    <header className="relative overflow-hidden pb-14 pt-48">
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0"
        // style={{
        //   backgroundImage:
        //     "radial-gradient(circle at 1px 1px, rgba(15, 23, 42, 0.28) 1px, transparent 0)",
        //   backgroundSize: "15px 15px",
        //   backgroundPositionX: "7.5px",
        //   backgroundPositionY: "7.5px",
        //   opacity: 0.2,
        // }}
      />

      <Container className="relative z-10 flex flex-col items-center justify-center space-y-8">
        <div className="text-center m-0 text-4xl lg:text-6xl font-medium leading-[1.05] tracking-[-0.02em]">
          <Translate id="homepage.hero.title">EteDrop 让传输更便利</Translate>
        </div>
        <p className="text-center m-0 text-sm lg:text-lg leading-relaxed text-slate-600 ">
          <Translate id="homepage.hero.subtitle">
            您的公网，内网，大文件传输工具。助您提升工作效率。
          </Translate>
        </p>

        <div className="flex flex-wrap items-center gap-3 pt-2">
          <ButtonLink
            to={primaryCta.to}
            variant="primary"
            size="lg"
            className="w-auto min-w-56 h-14 text-xl"
            download={primaryCta.download}
            iconPosition="left"
            icon={
              primaryCta.icon ? (
                <img
                  src={primaryCta.icon}
                  alt=""
                  className="h-7 w-7 pb-0.5 shrink-0 object-contain"
                  decoding="async"
                />
              ) : undefined
            }
          >
            <Translate id="homepage.hero.primaryCta">立即下载</Translate>
          </ButtonLink>
        </div>
        <div className="h-1 lg:h-4"></div>
        <div className="aspect-video rounded-xl lg:rounded-[32px] overflow-hidden">
          <video
            src={shareVideoSrc}
            autoPlay
            loop
            muted
            playsInline
            className="w-full h-full object-cover"
          />
        </div>
        <div className="h-4 lg:h-24"></div>
      </Container>
    </header>
  );
}
