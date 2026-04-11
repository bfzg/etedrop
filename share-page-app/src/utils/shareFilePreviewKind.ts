/** 与 Flutter `share_preview_kind.dart` 扩展名集合对齐，便于两端一致判断 */

export type SharePreviewKind = "video" | "image" | "pdf" | "audio" | "text" | "none";

const VIDEO_STREAM_EXTS = new Set(["mp4"]);

const IMAGE_EXTS = new Set([
  "jpg",
  "jpeg",
  "png",
  "gif",
  "bmp",
  "webp",
  "ico",
  "svg",
]);

const AUDIO_EXTS = new Set(["mp3", "wav", "ogg", "m4a", "aac", "flac", "opus"]);

const TEXT_EXTS = new Set([
  "txt",
  "text",
  "md",
  "log",
  "json",
  "xml",
  "yaml",
  "yml",
  "toml",
  "ini",
  "csv",
  "tsv",
  "js",
  "mjs",
  "cjs",
  "ts",
  "jsx",
  "tsx",
  "vue",
  "svelte",
  "py",
  "dart",
  "java",
  "go",
  "rs",
  "c",
  "cc",
  "cpp",
  "h",
  "hpp",
  "cs",
  "kt",
  "swift",
  "rb",
  "php",
  "sh",
  "bash",
  "zsh",
  "sql",
  "graphql",
  "html",
  "htm",
  "css",
  "scss",
  "sass",
  "less",
  "env",
  "gitignore",
  "dockerignore",
  "properties",
  "gradle",
  "cmake",
  "lock",
]);

function fileExtension(fileName: string): string {
  const t = fileName.trim();
  const i = t.lastIndexOf(".");
  if (i <= 0 || i === t.length - 1) return "";
  return t.slice(i + 1).toLowerCase();
}

/** 是否可用浏览器内建能力做「预览」（不含 Office 等需专用软件的类型） */
export function getSharePreviewKind(fileName: string): SharePreviewKind {
  const ext = fileExtension(fileName);
  if (!ext) return "none";
  if (ext === "pdf") return "pdf";
  if (VIDEO_STREAM_EXTS.has(ext)) return "video";
  if (IMAGE_EXTS.has(ext)) return "image";
  if (AUDIO_EXTS.has(ext)) return "audio";
  if (TEXT_EXTS.has(ext)) return "text";
  return "none";
}

/** 流式 MSE 仅用于 MP4；其它可预览类型走整文件下载后 blob 展示 */
export function getPlayDownloadOptions(
  fileName: string,
  canPlayWithoutMse: boolean,
): { remuxFmp4: boolean; stream: boolean } {
  const kind = getSharePreviewKind(fileName);
  if (kind !== "video") {
    return { remuxFmp4: false, stream: false };
  }
  return { remuxFmp4: true, stream: !canPlayWithoutMse };
}

/** 为整文件预览 Blob 补全 MIME，改善 <audio> / 部分环境行为 */
export function guessMimeTypeForFileName(fileName: string): string | undefined {
  const ext = fileExtension(fileName);
  const map: Record<string, string> = {
    mp4: "video/mp4",
    webp: "image/webp",
    png: "image/png",
    jpg: "image/jpeg",
    jpeg: "image/jpeg",
    gif: "image/gif",
    bmp: "image/bmp",
    svg: "image/svg+xml",
    ico: "image/x-icon",
    pdf: "application/pdf",
    mp3: "audio/mpeg",
    wav: "audio/wav",
    ogg: "audio/ogg",
    m4a: "audio/mp4",
    aac: "audio/aac",
    flac: "audio/flac",
    opus: "audio/opus",
    txt: "text/plain",
    text: "text/plain",
    md: "text/markdown",
    log: "text/plain",
    json: "application/json",
    xml: "application/xml",
    csv: "text/csv",
    tsv: "text/tab-separated-values",
    html: "text/html",
    htm: "text/html",
    css: "text/css",
    js: "text/javascript",
    mjs: "text/javascript",
    cjs: "text/javascript",
    ts: "text/plain",
    jsx: "text/plain",
    tsx: "text/plain",
    vue: "text/plain",
    yaml: "text/yaml",
    yml: "text/yaml",
  };
  return map[ext];
}
