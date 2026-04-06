/**
 * 将安装包放到 `website/static/downloads/`，文件名需与此处一致。
 * 若尚未上传文件，点击下载会得到 404，部署前请放入对应产物。
 */
export const DOWNLOAD_INSTALLERS = {
  windows: "/downloads/EteDrop-Windows-x64.exe",
  macos: "/downloads/EteDrop-macOS.dmg",
} as const;
