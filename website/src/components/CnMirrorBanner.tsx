import type { ReactNode } from "react";
import { useCallback, useEffect, useMemo, useState } from "react";
import ExecutionEnvironment from "@docusaurus/ExecutionEnvironment";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Translate from "@docusaurus/Translate";
import {
  CN_MIRROR_DISMISS_KEY,
  isGlobalMarketingHost,
  isLikelyMainlandChinaClient,
} from "@site/src/constant/regions";

type CustomFields = {
  chinaMirrorOrigin?: string;
  cnMirrorBannerDebug?: boolean;
};

function readDismissed(): boolean {
  try {
    return globalThis.localStorage?.getItem(CN_MIRROR_DISMISS_KEY) === "1";
  } catch {
    return false;
  }
}

function CnMirrorBannerInner(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  const custom = (siteConfig.customFields ?? {}) as CustomFields;
  const mirrorOrigin = (
    custom.chinaMirrorOrigin ?? "https://cn.etedrop.com"
  ).replace(/\/$/, "");
  const debug = Boolean(custom.cnMirrorBannerDebug);

  const [dismissed, setDismissed] = useState(readDismissed);

  const mirrorHost = useMemo(() => {
    try {
      return new URL(mirrorOrigin).hostname.toLowerCase();
    } catch {
      return "";
    }
  }, [mirrorOrigin]);

  const visible = useMemo(() => {
    if (typeof window === "undefined" || dismissed) {
      return false;
    }
    const host = window.location.hostname.toLowerCase();
    if (mirrorHost && host === mirrorHost) {
      return false;
    }
    const onGlobal =
      debug || isGlobalMarketingHost(window.location.hostname);
    if (!onGlobal) {
      return false;
    }
    return isLikelyMainlandChinaClient();
  }, [debug, dismissed, mirrorHost]);

  const mirrorHref = useMemo(() => {
    return "https://etedrop.cn";
  }, []);

  const onDismiss = useCallback(() => {
    try {
      globalThis.localStorage?.setItem(CN_MIRROR_DISMISS_KEY, "1");
    } catch {
      /* private mode */
    }
    setDismissed(true);
  }, []);

  if (!visible) {
    return null;
  }

  return (
    <div
      className="cn-mirror-banner sticky top-0 z-[300] border-b border-amber-200/80 bg-amber-50 text-slate-900 shadow-sm"
      role="region"
      aria-label="China mirror notice"
    >
      <div className="mx-auto flex max-w-6xl flex-col gap-2 px-4 py-2 text-sm sm:flex-row sm:items-center sm:justify-between sm:gap-4 sm:text-[0.9375rem]">
        <div className="min-w-0 leading-snug">
          <span className="font-medium text-amber-950">
            <Translate id="cnMirror.banner.title">
              检测到您可能位于中国大陆
            </Translate>
          </span>
          <span className="text-slate-700">
            {" "}
            <Translate id="cnMirror.banner.body">
              访问国内节点页面加载通常更快（独立域名与证书，需在 DNS 将 cn 指向中国服务器）。
            </Translate>
          </span>
        </div>
        <div className="flex shrink-0 flex-wrap items-center gap-2 sm:justify-end">
          <a
            href={mirrorHref}
            className="inline-flex items-center justify-center rounded-lg bg-amber-700 px-3 py-1.5 text-sm font-medium text-white shadow-sm transition hover:bg-amber-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber-700"
          >
            <Translate id="cnMirror.banner.cta">前往国内站点</Translate>
          </a>
          <button
            type="button"
            onClick={onDismiss}
            className="rounded-lg border-none bg-white px-3 py-1.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-400"
          >
            <Translate id="cnMirror.banner.dismiss">不再提示</Translate>
          </button>
        </div>
      </div>
    </div>
  );
}

/** 主站（etedrop.com）上向可能的大陆用户提示访问 cn 镜像 */
export default function CnMirrorBanner(): ReactNode {
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!ExecutionEnvironment.canUseDOM || !mounted) {
    return null;
  }

  return <CnMirrorBannerInner />;
}
