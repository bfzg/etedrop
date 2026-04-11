import { useMemo, useState } from "react";
import { useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useSharePage } from "../hooks/useSharePage";
import { formatBytes } from "../utils/format";
import { FileIconSvg } from "../components/fileIconSvgComponent";
import { ShareFilePreview } from "../components/ShareFilePreview";
import { isIOS, isMobile, isSafari, isWeChat } from "../utils/env";
import {
  getPlayDownloadOptions,
  getSharePreviewKind,
} from "../utils/shareFilePreviewKind";
import { hasOpfs } from "../utils/shareDownloadStorage";
import { SUPPORTED } from "../i18n";

const STATUS_CLASSES = {
  pending: {
    el: "flex items-center gap-2 py-3 px-4 rounded-lg mb-4 text-sm bg-amber-50 text-amber-800",
    dot: "w-2 h-2 rounded-full shrink-0 bg-amber-500 animate-pulse",
  },
  online: {
    el: "flex items-center gap-2 py-3 px-4 rounded-lg mb-4 text-sm bg-green-50 text-green-700",
    dot: "w-2 h-2 rounded-full shrink-0 bg-green-500",
  },
  error: {
    el: "flex items-center gap-2 py-3 px-4 rounded-lg mb-4 text-sm bg-red-50 text-red-600",
    dot: "w-2 h-2 rounded-full shrink-0 bg-red-500",
  },
} as const;

const LANG_LABELS: Record<string, string> = {
  en: "English",
  zh: "简体中文",
  ja: "日本語",
  ko: "한국어",
  es: "Español",
};

export function SharePageView() {
  const { t, i18n } = useTranslation();
  const { deviceId, shareCode } = useParams<{
    deviceId: string;
    shareCode: string;
  }>();
  const [password, setPassword] = useState("");
  const [emptyPwdError, setEmptyPwdError] = useState(false);

  if (!deviceId || !shareCode) {
    return (
      <div className="min-h-screen flex items-center justify-center p-5 text-red-600">
        {t("share.missingParams")}
      </div>
    );
  }

  const {
    status,
    showStatusBar,
    fileInfo,
    showPassword,
    passwordError,
    verifyLoading,
    showDownloadBtn,
    showProgress,
    progress,
    showDone,
    doneKind,
    showReconnect,
    downloadError,
    sendVerify,
    sendDownloadStart,
    sendSeek,
    reconnect,
    resumeHintBytes,
    playUrl,
    mseUrl,
    streaming,
    streamDuration,
    setPlaybackTime,
  } = useSharePage(deviceId, shareCode);

  const previewMediaUrl = mseUrl || playUrl;
  const previewKind = getSharePreviewKind(fileInfo?.fileName ?? "");
  const inWeChat = isWeChat();
  const safariBrowser = isSafari();
  const isWechatIOS = inWeChat && isIOS();
  const isWechatMobile = inWeChat && isMobile();
  const opfsAvailable = hasOpfs();
  const mediaSourceAvailable =
    typeof window !== "undefined" && "MediaSource" in window;
  const wechatDownloadSoftLimitBytes = 10 * 1024 * 1024;
  const wechatCanPlay = mediaSourceAvailable;
  /** 微信内：仍展示下载按钮但禁用，并提示用系统浏览器（如 Chrome）打开 */
  const showDownloadUi = showDownloadBtn;
  const downloadActionEnabled = showDownloadBtn && !inWeChat;
  const wechatAllowsInBrowserPreview =
    previewKind !== "video" || wechatCanPlay;
  const showPlayAction =
    showDownloadBtn &&
    previewKind !== "none" &&
    (!inWeChat || wechatAllowsInBrowserPreview);
  const canPlayWithoutMse = isIOS() && !mediaSourceAvailable;

  const statusStyle = STATUS_CLASSES[status.kind] ?? STATUS_CLASSES.error;

  const displayPasswordError = emptyPwdError
    ? t("share.enterPassword")
    : passwordError;

  const handleVerify = () => {
    const p = password.trim();
    if (!p) {
      setEmptyPwdError(true);
      return;
    }
    setEmptyPwdError(false);
    sendVerify(p);
  };

  const changeLanguage = (lng: string) => {
    void i18n.changeLanguage(lng);
    localStorage.setItem("i18nextLng", lng);
  };

  const currentLng = useMemo(() => {
    const base = (i18n.resolvedLanguage ?? i18n.language)
      .split("-")[0]
      .toLowerCase();
    return SUPPORTED.includes(base as (typeof SUPPORTED)[number]) ? base : "en";
  }, [i18n.resolvedLanguage, i18n.language]);

  return (
    <>
      {isWechatMobile && (
        <img
          src={`${import.meta.env.BASE_URL}img/wechat.png`}
          alt={t("share.wechatAlt")}
          className="w-full rounded-xl bg-white"
          fetchPriority="high"
        />
      )}
      <div
        className={`flex items-center justify-center ${isWechatMobile ? "px-5" : "min-h-screen p-5"}`}
      >
        <div className="max-w-[440px] w-full">
          <div className="flex items-center justify-between gap-3 mb-6 min-w-0">
            <div className="flex items-center gap-3 min-w-0 flex-1">
              <img
                src={`${import.meta.env.BASE_URL}img/app_icon.png`}
                alt=""
                className="w-10 h-10 rounded-2xl shrink-0 object-contain"
                width={40}
                height={40}
                fetchPriority="high"
                decoding="sync"
              />
              <div className="text-2xl font-bold text-gray-800 truncate">
                {t("share.brand")}
              </div>
            </div>
            <div className="relative shrink-0">
              <select
                className="cursor-pointer rounded-xl bg-white py-2 w-22 text-sm font-medium text-slate-800 transition "
                aria-label={t("share.language")}
                value={currentLng}
                onChange={(e) => changeLanguage(e.target.value)}
              >
                {SUPPORTED.map((lng) => (
                  <option key={lng} value={lng}>
                    {LANG_LABELS[lng] ?? lng}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {inWeChat && (
            <div className="mb-4">
              <div className="mt-2 text-xs text-slate-600">
                {t("share.wechatInBrowser")}
                {opfsAvailable
                  ? t("share.wechatOpfsOn")
                  : t("share.wechatOpfsOff")}
                {!opfsAvailable && isWechatMobile && (
                  <span>
                    {t("share.wechatMobileLimit", {
                      size: formatBytes(wechatDownloadSoftLimitBytes),
                    })}
                  </span>
                )}
                {!opfsAvailable && !isWechatMobile && (
                  <span>{t("share.wechatDesktopHint")}</span>
                )}
              </div>
            </div>
          )}

          {showStatusBar && (
            <div className={statusStyle.el}>
              <span className={statusStyle.dot} />
              <span>{status.text}</span>
            </div>
          )}

          {fileInfo && (
            <div className="bg-slate-50 rounded-xl p-5 mb-4">
              <FileIconSvg
                fileName={fileInfo.fileName}
                className="w-12 h-12 mb-3"
                alt=""
              />
              <div className="text-base font-semibold text-slate-800 break-all mb-1">
                {fileInfo.fileName}
              </div>
              <div className="text-[13px] text-slate-500">
                {formatBytes(fileInfo.fileSize)}
              </div>
            </div>
          )}

          {previewMediaUrl && (
            <ShareFilePreview
              fileName={fileInfo?.fileName ?? ""}
              mediaUrl={previewMediaUrl}
              streaming={streaming}
              streamDuration={streamDuration}
              fileSize={fileInfo?.fileSize}
              onSeek={sendSeek}
              onPlaybackTime={setPlaybackTime}
              onVideoError={(err) => {
                console.error("[fastsend] video error", err);
              }}
            />
          )}

          {showPassword && (
            <div className="mb-4">
              <label
                className="block text-[13px] text-slate-600 mb-1.5 font-medium"
                htmlFor="share-password-input"
              >
                {t("share.passwordRequired")}
              </label>
              <div className="flex flex-col gap-2 sm:flex-row sm:items-stretch sm:gap-2">
                <input
                  id="share-password-input"
                  type="password"
                  name="password"
                  autoComplete="current-password"
                  enterKeyHint="go"
                  inputMode="text"
                  value={password}
                  onChange={(e) => {
                    setPassword(e.target.value);
                    setEmptyPwdError(false);
                  }}
                  onKeyDown={(e) => e.key === "Enter" && handleVerify()}
                  placeholder={t("share.passwordPlaceholder")}
                  className="w-full min-w-0 min-h-[44px] py-2.5 px-3.5 bg-gray-100 rounded-lg text-base outline-none border border-transparent focus:border-[#0052D9] focus:ring-1 focus:ring-[#0052D9] sm:flex-1"
                />
                <button
                  type="button"
                  disabled={verifyLoading}
                  onClick={handleVerify}
                  className="inline-flex items-center justify-center gap-1.5 min-h-[44px] py-2.5 px-5 rounded-lg text-base font-medium bg-[#0052D9] text-white cursor-pointer hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed w-full sm:w-auto sm:min-w-[100px] sm:shrink-0"
                >
                  {t("share.verify")}
                </button>
              </div>
              {displayPasswordError && (
                <div className="text-xs text-red-500 mt-1">
                  {displayPasswordError}
                </div>
              )}
            </div>
          )}

          {(showPlayAction || showDownloadUi) && (
            <>
              <div
                className={`grid gap-2 ${showPlayAction && showDownloadUi ? "grid-cols-2" : "grid-cols-1"}`}
              >
                {showPlayAction && (
                  <button
                    type="button"
                    disabled={
                      !fileInfo || (safariBrowser && previewKind === "video")
                    }
                    title={
                      safariBrowser && previewKind === "video"
                        ? t("share.safariPlayNotSupported")
                        : undefined
                    }
                    aria-label={
                      safariBrowser && previewKind === "video"
                        ? `${t("share.preview")} — ${t("share.safariPlayNotSupported")}`
                        : previewKind === "video"
                          ? t("share.play")
                          : t("share.preview")
                    }
                    onClick={() => {
                      if (!fileInfo) return;
                      const opts = getPlayDownloadOptions(
                        fileInfo.fileName,
                        canPlayWithoutMse,
                      );
                      void sendDownloadStart({
                        intent: "play",
                        remuxFmp4: opts.remuxFmp4,
                        stream: opts.stream,
                      });
                    }}
                    className="flex items-center justify-center gap-1.5 py-3 px-6 rounded-lg text-[15px] font-medium bg-[#0052D9] text-white cursor-pointer w-full hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {previewKind === "video"
                      ? t("share.play")
                      : t("share.preview")}
                  </button>
                )}

                {showDownloadUi && (
                  <button
                    type="button"
                    disabled={!downloadActionEnabled}
                    title={
                      inWeChat ? t("share.wechatDownloadNotSupported") : undefined
                    }
                    aria-label={
                      inWeChat
                        ? `${t("share.download")} — ${t("share.wechatDownloadNotSupported")}`
                        : resumeHintBytes > 0
                          ? t("share.resumeDownload", {
                              size: formatBytes(resumeHintBytes),
                            })
                          : t("share.download")
                    }
                    onClick={() => {
                      if (!downloadActionEnabled) return;
                      void sendDownloadStart({
                        intent: "download",
                        remuxFmp4: false,
                        stream: false,
                      });
                    }}
                    className="flex items-center justify-center gap-1.5 py-3 px-6 rounded-lg text-[15px] font-medium bg-slate-900 text-white cursor-pointer w-full hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {resumeHintBytes > 0
                      ? t("share.resumeDownload", {
                          size: formatBytes(resumeHintBytes),
                        })
                      : t("share.download")}
                  </button>
                )}
              </div>
              {inWeChat && showDownloadBtn && (
                <p className="mt-2 text-xs text-slate-500 text-left">
                  {t("share.wechatDownloadNotSupported")}
                </p>
              )}
              {safariBrowser &&
                showPlayAction &&
                previewKind === "video" && (
                <p className="mt-2 text-xs text-slate-500 text-left">
                  {t("share.safariPlayNotSupported")}
                </p>
              )}
            </>
          )}

          {canPlayWithoutMse && previewKind === "video" && (
            <div className="mt-2 text-xs text-slate-600 text-center">
              {t("share.iosNoStream")}
            </div>
          )}

          {inWeChat && showDownloadBtn && (
            <div className="mt-3 text-xs text-slate-600 text-center">
              {isWechatIOS &&
                !wechatCanPlay &&
                previewKind === "video" &&
                t("share.wechatNoPlay")}
            </div>
          )}

          {showProgress && (
            <div className="mt-4">
              <div className="text-xs text-slate-500 text-center">
                {formatBytes(progress.received)} / {formatBytes(progress.total)}{" "}
                (
                {progress.total > 0
                  ? Math.min(
                      100,
                      (progress.received / progress.total) * 100,
                    ).toFixed(1)
                  : 0}
                %)
              </div>
            </div>
          )}

          {!!downloadError && (
            <div className="mt-3 rounded-lg bg-amber-50 text-amber-900 px-3 py-2 text-xs">
              {downloadError}
            </div>
          )}

          {showDone &&
            !streaming &&
            doneKind !== "stream" &&
            !playUrl && (
            <div className="text-center py-5">
              <div className="text-4xl mb-2">✅</div>
              <p className="text-green-600 font-medium">
                {t("share.downloadComplete")}
              </p>
            </div>
          )}

          {showReconnect && (
            <button
              type="button"
              onClick={reconnect}
              className="inline-flex items-center justify-center gap-1.5 py-3 px-6 rounded-lg text-[15px] font-medium w-full mt-3 bg-slate-100 text-slate-600 cursor-pointer hover:bg-slate-200"
            >
              {t("share.reconnect")}
            </button>
          )}

          <div className="mt-6 pt-4 border-t border-slate-200/80">
            <p className="text-base font-medium text-slate-700 mb-2.5">
              {t("share.compatibilityTipsTitle")}
            </p>
            <ol className="list-decimal pl-4 space-y-2 text-base leading-relaxed text-slate-600 marker:text-slate-400">
              <li>{t("share.compatibilityTip1")}</li>
              <li>{t("share.compatibilityTip2")}</li>
            </ol>
            <p className="mt-4 text-sm text-slate-600 leading-relaxed">
              <span className="font-medium text-slate-700">
                {t("share.feedbackTitle")}
              </span>
              <span className="mx-1">{t("share.feedbackEmailLabel")}</span>
              <a
                href="mailto:yuanzhou_cn@qq.com"
                className="text-[#0052D9] underline underline-offset-2 break-all"
              >
                yuanzhou_cn@qq.com
              </a>
            </p>
          </div>
        </div>
      </div>
    </>
  );
}
