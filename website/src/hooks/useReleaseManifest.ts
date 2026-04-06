import { useEffect, useLayoutEffect, useState } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import { getClientDownloadPlatform, type ClientDesktopPlatform } from "@site/src/constant/release";
import {
  FALLBACK_RELEASE,
  type ReleaseManifest,
  VERSION_JSON_PUBLIC_PATH,
} from "@site/src/constant/release";

function mergeManifest(raw: unknown): ReleaseManifest {
  if (!raw || typeof raw !== "object") {
    return FALLBACK_RELEASE;
  }
  const o = raw as Record<string, unknown>;
  const version = typeof o.version === "string" ? o.version : FALLBACK_RELEASE.version;
  const d = o.downloads;
  const downloads =
    d && typeof d === "object"
      ? {
          windows:
            typeof (d as Record<string, unknown>).windows === "string"
              ? ((d as Record<string, unknown>).windows as string)
              : FALLBACK_RELEASE.downloads.windows,
          macos:
            typeof (d as Record<string, unknown>).macos === "string"
              ? ((d as Record<string, unknown>).macos as string)
              : FALLBACK_RELEASE.downloads.macos,
        }
      : FALLBACK_RELEASE.downloads;
  return { version, downloads };
}

export function useReleaseManifest(): ReleaseManifest {
  const jsonUrl = useBaseUrl(VERSION_JSON_PUBLIC_PATH);
  const [manifest, setManifest] = useState<ReleaseManifest>(FALLBACK_RELEASE);

  useEffect(() => {
    let cancelled = false;
    fetch(jsonUrl)
      .then((res) => (res.ok ? res.json() : null))
      .then((data: unknown) => {
        if (!cancelled && data) {
          setManifest(mergeManifest(data));
        }
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [jsonUrl]);

  return manifest;
}

/** 相对站点路径交给 `useBaseUrl`；http(s) 外链由 `useBaseUrl` 原样放行 */
export function useResolvedDownloadHref(pathOrUrl: string): string {
  const normalized = /^https?:\/\//i.test(pathOrUrl)
    ? pathOrUrl
    : pathOrUrl.startsWith("/")
      ? pathOrUrl
      : `/${pathOrUrl}`;
  return useBaseUrl(normalized);
}

export function useClientDownloadPlatform(): ClientDesktopPlatform {
  const [platform, setPlatform] = useState<ClientDesktopPlatform>("unknown");
  useLayoutEffect(() => {
    setPlatform(getClientDownloadPlatform());
  }, []);
  return platform;
}
