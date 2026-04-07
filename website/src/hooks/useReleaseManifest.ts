import { useEffect, useLayoutEffect, useState } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import {
  getClientDownloadPlatform,
  type ClientDesktopPlatform,
} from "@site/src/constant/release";
import {
  FALLBACK_RELEASE,
  type ReleaseManifest,
  VERSION_JSON_PUBLIC_PATH,
} from "@site/src/constant/release";

function toStringArray(raw: unknown): string[] {
  if (!Array.isArray(raw)) {
    return [];
  }
  return raw
    .map((item) => (typeof item === "string" ? item.trim() : ""))
    .filter(Boolean);
}

function mergeManifest(raw: unknown): ReleaseManifest {
  if (!raw || typeof raw !== "object") {
    return FALLBACK_RELEASE;
  }
  const o = raw as Record<string, unknown>;
  const latestVersion =
    typeof o.latestVersion === "string"
      ? o.latestVersion
      : FALLBACK_RELEASE.latestVersion;
  const windowsDownloadUrl =
    typeof o.windowsDownloadUrl === "string"
      ? o.windowsDownloadUrl
      : FALLBACK_RELEASE.windowsDownloadUrl;
  const macDownloadUrl =
    typeof o.macDownloadUrl === "string"
      ? o.macDownloadUrl
      : FALLBACK_RELEASE.macDownloadUrl;
  const linuxDownloadUrl =
    typeof o.linuxDownloadUrl === "string"
      ? o.linuxDownloadUrl
      : FALLBACK_RELEASE.linuxDownloadUrl;
  const iosDownloadUrl =
    typeof o.iosDownloadUrl === "string"
      ? o.iosDownloadUrl
      : FALLBACK_RELEASE.iosDownloadUrl;
  const androidDownloadUrl =
    typeof o.androidDownloadUrl === "string"
      ? o.androidDownloadUrl
      : FALLBACK_RELEASE.androidDownloadUrl;
  const forceUpdate =
    typeof o.forceUpdate === "boolean" ? o.forceUpdate : FALLBACK_RELEASE.forceUpdate;
  const releasePageUrl =
    typeof o.releasePageUrl === "string"
      ? o.releasePageUrl
      : FALLBACK_RELEASE.releasePageUrl;

  const notesRaw = o.releaseNotes;
  const releaseNotes: Record<string, string[]> =
    notesRaw && typeof notesRaw === "object"
      ? {
          zh: toStringArray((notesRaw as Record<string, unknown>).zh),
          en: toStringArray((notesRaw as Record<string, unknown>).en),
          ja: toStringArray((notesRaw as Record<string, unknown>).ja),
          ko: toStringArray((notesRaw as Record<string, unknown>).ko),
          es: toStringArray((notesRaw as Record<string, unknown>).es),
        }
      : FALLBACK_RELEASE.releaseNotes;

  return {
    latestVersion,
    windowsDownloadUrl,
    macDownloadUrl,
    linuxDownloadUrl,
    iosDownloadUrl,
    androidDownloadUrl,
    forceUpdate,
    releasePageUrl,
    releaseNotes,
  };
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
  const input = pathOrUrl.trim();
  const normalized = !input
    ? "/"
    : /^https?:\/\//i.test(input)
      ? input
      : input.startsWith("/")
        ? input
        : `/${input}`;
  const resolved = useBaseUrl(normalized);
  return input ? resolved : "";
}

export function useClientDownloadPlatform(): ClientDesktopPlatform {
  const [platform, setPlatform] = useState<ClientDesktopPlatform>("unknown");
  useLayoutEffect(() => {
    setPlatform(getClientDownloadPlatform());
  }, []);
  return platform;
}
