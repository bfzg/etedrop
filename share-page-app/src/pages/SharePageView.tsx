import { useMemo, useState } from "react";
import { useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useSharePage } from "../hooks/useSharePage";
import { formatBytes } from "../utils/format";
import { FileIconSvg } from "../components/fileIconSvgComponent";
import { VideoPlayer } from "../components/VideoPlayer";
import { isIOS, isMobile, isWeChat } from "../utils/env";
import { hasOpfs } from "../utils/shareDownloadStorage";
import { SUPPORTED } from "../i18n";

const VIDEO_EXTS = new Set(["mp4"]);

function isLikelyVideo(fileName: string) {
  const i = fileName.lastIndexOf(".");
  if (i < 0) return false;
  const ext = fileName.slice(i + 1).toLowerCase();
  return VIDEO_EXTS.has(ext);
}

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

  const videoSrc = mseUrl || playUrl;
  const inWeChat = isWeChat();
  const isWechatIOS = inWeChat && isIOS();
  const isWechatMobile = inWeChat && isMobile();
  const opfsAvailable = hasOpfs();
  const mediaSourceAvailable =
    typeof window !== "undefined" && "MediaSource" in window;
  const wechatDownloadSoftLimitBytes = 10 * 1024 * 1024;
  const fileSize = fileInfo?.fileSize ?? 0;
  const wechatCanDownload =
    !isWechatMobile ||
    opfsAvailable ||
    fileSize <= wechatDownloadSoftLimitBytes;
  const wechatCanPlay = mediaSourceAvailable;
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
    return SUPPORTED.includes(base as (typeof SUPPORTED)[number])
      ? base
      : "en";
  }, [i18n.resolvedLanguage, i18n.language]);

  return (
    <>
      {isWechatMobile && (
        <img
          src={`${import.meta.env.BASE_URL}img/wechat.png`}
          alt={t("share.wechatAlt")}
          className="w-full rounded-xl bg-white"
        />
      )}
      <div
        className={`flex items-center justify-center ${isWechatMobile ? "px-5" : "min-h-screen p-5"}`}
      >
        <div className="max-w-[440px] w-full">
          <div className="flex items-center gap-3 mb-1 min-w-0">
            <img
              src={`${import.meta.env.BASE_URL}img/app_icon.png`}
              alt=""
              className="w-10 h-10 rounded-2xl shrink-0 object-contain"
              width={40}
              height={40}
              decoding="async"
            />
            <div className="text-2xl font-bold text-gray-800 truncate">
              {t("share.brand")}
            </div>
          </div>
          <p className="text-[13px] text-gray-500 mb-6">
            {t("share.shareCode", { code: shareCode })}
          </p>

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

          {videoSrc && (
            <VideoPlayer
              src={videoSrc}
              streaming={streaming}
              duration={streamDuration}
              onSeek={sendSeek}
              onPlaybackTime={setPlaybackTime}
              onError={(err) => {
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
                  className="w-full min-w-0 min-h-[44px] py-2.5 px-3.5 bg-gray-100 rounded-lg text-base outline-none border border-transparent focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 sm:flex-1"
                />
                <button
                  type="button"
                  disabled={verifyLoading}
                  onClick={handleVerify}
                  className="inline-flex items-center justify-center gap-1.5 min-h-[44px] py-2.5 px-5 rounded-lg text-base font-medium bg-indigo-600 text-white cursor-pointer hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed w-full sm:w-auto sm:min-w-[100px] sm:shrink-0"
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

          {showDownloadBtn && (
            <div className="grid grid-cols-2 gap-2">
              {(!inWeChat || wechatCanPlay) &&
                isLikelyVideo(fileInfo?.fileName ?? "") && (
                  <button
                    type="button"
                    disabled={
                      !fileInfo || !isLikelyVideo(fileInfo?.fileName ?? "")
                    }
                    onClick={() => {
                      void sendDownloadStart({
                        intent: "play",
                        remuxFmp4: true,
                        stream: !canPlayWithoutMse,
                      });
                    }}
                    className="flex items-center justify-center gap-1.5 py-3 px-6 rounded-lg text-[15px] font-medium bg-indigo-600 text-white cursor-pointer w-full hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {t("share.play")}
                  </button>
                )}

              {(!inWeChat || wechatCanDownload) && (
                <button
                  type="button"
                  onClick={() => {
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
          )}

          {canPlayWithoutMse && isLikelyVideo(fileInfo?.fileName ?? "") && (
            <div className="mt-2 text-xs text-slate-600 text-center">
              {t("share.iosNoStream")}
            </div>
          )}

          {inWeChat && showDownloadBtn && (
            <div className="mt-3 text-xs text-slate-600 text-center">
              {isWechatIOS && !wechatCanPlay && t("share.wechatNoPlay")}
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

          {showDone && !streaming && doneKind !== "stream" && (
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

          <div className="mt-8 pt-4 border-t border-slate-200">
            <label className="flex items-center justify-between gap-3 text-[13px] text-slate-600">
              <span>{t("share.language")}</span>
              <select
                className="rounded-lg border border-slate-200 bg-white py-1.5 px-2 text-sm text-slate-800"
                value={currentLng}
                onChange={(e) => changeLanguage(e.target.value)}
              >
                {SUPPORTED.map((lng) => (
                  <option key={lng} value={lng}>
                    {LANG_LABELS[lng] ?? lng}
                  </option>
                ))}
              </select>
            </label>
          </div>
        </div>
      </div>
    </>
  );
}
