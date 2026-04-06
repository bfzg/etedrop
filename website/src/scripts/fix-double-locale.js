import ExecutionEnvironment from "@docusaurus/ExecutionEnvironment";

const LOCALES = new Set(["zh-Hans", "en", "ja", "es", "ko"]);

/**
 * Normalize broken i18n paths:
 *
 * 1) /en/en/ — duplicate same locale (clip one).
 * 2) /ko/ja/en/ — language switch stacked because pathnameSuffix was wrong (baseUrl replace
 *    only strips one `/` when baseUrl is `/`, etc.). Keep the last locale segment in the run
 *    and append the real path after it.
 *
 * Valid paths like /en/docs/foo have only one leading locale segment and are unchanged.
 */
function normalizeLocalePath(pathname) {
  const hadTrailingSlash = pathname.endsWith("/") && pathname !== "/";
  let segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) {
    return null;
  }

  while (
    segments.length >= 2 &&
    segments[0] === segments[1] &&
    LOCALES.has(segments[0])
  ) {
    segments = [segments[0], ...segments.slice(2)];
  }

  let i = 0;
  while (i < segments.length && LOCALES.has(segments[i])) {
    i += 1;
  }

  if (i >= 2) {
    const chosen = segments[i - 1];
    const rest = segments.slice(i);
    segments = [chosen, ...rest];
  }

  let out = "/" + segments.join("/");
  if (hadTrailingSlash && !out.endsWith("/")) {
    out += "/";
  }

  return out === pathname ? null : out;
}

function redirectIfNeeded() {
  if (!ExecutionEnvironment.canUseDOM) {
    return;
  }
  const { pathname, search, hash } = window.location;
  const fixed = normalizeLocalePath(pathname);
  if (fixed) {
    window.location.replace(fixed + search + hash);
  }
}

if (ExecutionEnvironment.canUseDOM) {
  redirectIfNeeded();
}

export function onRouteUpdate() {
  redirectIfNeeded();
}
