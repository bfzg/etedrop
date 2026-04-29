import { useEffect, useLayoutEffect, useState } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import {
  getClientDownloadPlatform,
  type ClientDesktopPlatform,
} from "@site/src/constant/release";
import {
  FALLBACK_RELEASE,
  type ReleaseChangelogEntry,
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

function trimVersion(raw: unknown): string {
  return typeof raw === "string" ? raw.trim() : "";
}

function mergeNotesObject(raw: unknown): Record<string, string[]> {
  if (!raw || typeof raw !== "object") {
    return {
      zh: [],
      en: [],
      ja: [],
      ko: [],
      es: [],
    };
  }
  const n = raw as Record<string, unknown>;
  return {
    zh: toStringArray(n.zh),
    en: toStringArray(n.en),
    ja: toStringArray(n.ja),
    ko: toStringArray(n.ko),
    es: toStringArray(n.es),
  };
}

function mergeChangelog(
  raw: unknown,
  latestVersion: string,
  fallbackNotes: Record<string, string[]>,
): ReleaseChangelogEntry[] {
  const fromJson: ReleaseChangelogEntry[] = [];
  if (Array.isArray(raw)) {
    for (const item of raw) {
      if (!item || typeof item !== "object") continue;
      const o = item as Record<string, unknown>;
      const version = trimVersion(o.version);
      if (!version) continue;
      fromJson.push({
        version,
        notes: mergeNotesObject(o.notes),
      });
    }
  }
  if (fromJson.length > 0) {
    return fromJson;
  }
  const hasAnyNote = Object.values(fallbackNotes).some((a) => a.length > 0);
  if (!hasAnyNote || !trimVersion(latestVersion)) {
    return [];
  }
  return [{ version: latestVersion, notes: { ...fallbackNotes } }];
}

function mergeManifest(raw: unknown): ReleaseManifest {
  if (!raw || typeof raw !== "object") {
    return FALLBACK_RELEASE;
  }
  const o = raw as Record<string, unknown>;
  const latestVersion =
    trimVersion(o.latestVersion) || FALLBACK_RELEASE.latestVersion;
  const windowsVersion = trimVersion(o.windowsVersion) || latestVersion;
  const macVersion = trimVersion(o.macVersion) || latestVersion;
  const linuxVersion = trimVersion(o.linuxVersion) || latestVersion;
  const iosVersion = trimVersion(o.iosVersion) || latestVersion;
  const androidVersion = trimVersion(o.androidVersion) || latestVersion;
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
      ? mergeNotesObject(notesRaw)
      : FALLBACK_RELEASE.releaseNotes;

  const changelog = mergeChangelog(o.changelog, latestVersion, releaseNotes);

  return {
    latestVersion,
    windowsVersion,
    macVersion,
    linuxVersion,
    iosVersion,
    androidVersion,
    windowsDownloadUrl,
    macDownloadUrl,
    linuxDownloadUrl,
    iosDownloadUrl,
    androidDownloadUrl,
    forceUpdate,
    releasePageUrl,
    releaseNotes,
    changelog,
  };
}

export function useReleaseManifest(): ReleaseManifest {
  const { siteConfig } = useDocusaurusContext();
  // Always read one shared manifest under site baseUrl (not locale-prefixed path).
  // This avoids maintaining duplicated `/xx/public/version.json` files per locale.
  const base = (siteConfig.baseUrl || "/").replace(/\/+$/, "");
  const jsonUrl = `${base}${VERSION_JSON_PUBLIC_PATH}`;
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
