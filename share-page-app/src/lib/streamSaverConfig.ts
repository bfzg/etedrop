import streamSaver from "./streamSaver";

/**
 * mitm 必须用绝对 base。`new URL(rel, '/share/')` 在部分环境下会抛 Invalid base URL；
 * 先用 `window.location.origin` 与 `BASE_URL` 合成绝对 URL。
 */
function shareAbsoluteBase(): string {
  const path = import.meta.env.BASE_URL || "/share/";
  if (typeof window === "undefined" || !window.location?.origin) {
    return path.endsWith("/") ? path : `${path}/`;
  }
  return new URL(path, window.location.origin).href;
}

streamSaver.mitm = new URL(
  "mitm.html?version=2.0.0",
  shareAbsoluteBase(),
).href;
