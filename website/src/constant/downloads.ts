import { FALLBACK_RELEASE } from "./release";

/** 与 `static/public/version.json` 中 downloads 默认一致；页面优先使用接口拉取的清单 */
export const DOWNLOAD_INSTALLERS = FALLBACK_RELEASE.downloads;
