import { useState } from "react";
import { useParams } from "react-router-dom";
import { useSharePage } from "../hooks/useSharePage";
import { formatBytes } from "../utils/format";
import { FileIconSvg } from "../components/fileIconSvgComponent";
import { VideoPlayer } from "../components/VideoPlayer";
import { isIOS, isMobile, isWeChat } from "../utils/env";
import { hasOpfs } from "../utils/shareDownloadStorage";

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

export function SharePageView() {
  const { deviceId, shareCode } = useParams<{
    deviceId: string;
    shareCode: string;
  }>();
  const [password, setPassword] = useState("");
  const [emptyPwdError, setEmptyPwdError] = useState(false);

  if (!deviceId || !shareCode) {
    return (
      <div className="min-h-screen flex items-center justify-center p-5 text-red-600">
        缺少设备 ID 或分享码
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
  // Only enforce the 10MB soft limit on mobile WeChat. Desktop WeChat can often
  // handle larger downloads even without OPFS.
  const wechatCanDownload =
    !isWechatMobile ||
    opfsAvailable ||
    fileSize <= wechatDownloadSoftLimitBytes;
  const wechatCanPlay = mediaSourceAvailable;
  const canPlayWithoutMse = isIOS() && !mediaSourceAvailable;

  const statusStyle = STATUS_CLASSES[status.kind] ?? STATUS_CLASSES.error;

  const displayPasswordError = emptyPwdError ? "请输入密码" : passwordError;

  const handleVerify = () => {
    const p = password.trim();
    if (!p) {
      setEmptyPwdError(true);
      return;
    }
    setEmptyPwdError(false);
    sendVerify(p);
  };

  return (
    <>
        {isWechatMobile && (
        <img
          src={`${import.meta.env.BASE_URL}img/wechat.png`}
          alt="请在浏览器打开"
          className="w-full rounded-xl bg-white"
        />
      )}
      <div
        className={`flex items-center justify-center ${isWechatMobile ? "px-5" : "min-h-screen p-5"}`}
      >
        <div className="max-w-[440px] w-full">
          {/* 仅微信内置浏览器展示引导图；用 BASE_URL 兼容 /share/ 子路径部署 */}

          <div className="text-2xl font-bold text-gray-800 mb-1">Eddy</div>
          <p className="text-[13px] text-gray-500 mb-6">分享码: {shareCode}</p>

          {inWeChat && (
            <div className="mb-4">
              <div className="mt-2 text-xs text-slate-600">
                微信内浏览器：{opfsAvailable ? "支持" : "不支持"}
                {!opfsAvailable && isWechatMobile && (
                  <span>
                    （仅允许下载 {formatBytes(wechatDownloadSoftLimitBytes)}{" "}
                    以内文件）
                  </span>
                )}
                {!opfsAvailable && !isWechatMobile && (
                  <span>（可能无法断点续传，但通常仍可下载）</span>
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
              <label className="block text-[13px] text-slate-600 mb-1.5 font-medium">
                此文件需要访问密码
              </label>
              <div className="flex gap-2">
                <input
                  type="password"
                  value={password}
                  onChange={(e) => {
                    setPassword(e.target.value);
                    setEmptyPwdError(false);
                  }}
                  onKeyDown={(e) => e.key === "Enter" && handleVerify()}
                  placeholder="请输入密码"
                  className="flex-1 py-2.5 px-3.5 bg-gray-100 rounded-lg text-sm outline-none"
                />
                <button
                  type="button"
                  disabled={verifyLoading}
                  onClick={handleVerify}
                  className="inline-flex items-center justify-center gap-1.5 py-2.5 px-5 rounded-lg text-sm font-medium bg-indigo-600 text-white cursor-pointer hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  验证
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
                        // iOS without MediaSource: fall back to full download then play via <video src=blob>.
                        stream: !canPlayWithoutMse,
                      });
                    }}
                    className="flex items-center justify-center gap-1.5 py-3 px-6 rounded-lg text-[15px] font-medium bg-indigo-600 text-white cursor-pointer w-full hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    播放
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
                    ? `继续下载（已保存 ${formatBytes(resumeHintBytes)}）`
                    : "下载"}
                </button>
              )}
            </div>
          )}

          {canPlayWithoutMse && isLikelyVideo(fileInfo?.fileName ?? "") && (
            <div className="mt-2 text-xs text-slate-600 text-center">
              iOS 当前环境不支持流式播放，需要先完整下载后才能播放
            </div>
          )}

          {inWeChat && showDownloadBtn && (
            <div className="mt-3 text-xs text-slate-600 text-center">
              {isWechatIOS && !wechatCanPlay && "（当前环境不支持在线播放）"}
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

          {showDone && !streaming && doneKind !== "stream" && (
            <div className="text-center py-5">
              <div className="text-4xl mb-2">✅</div>
              <p className="text-green-600 font-medium">下载完成</p>
            </div>
          )}

          {showReconnect && (
            <button
              type="button"
              onClick={reconnect}
              className="inline-flex items-center justify-center gap-1.5 py-3 px-6 rounded-lg text-[15px] font-medium w-full mt-3 bg-slate-100 text-slate-600 cursor-pointer hover:bg-slate-200"
            >
              重新连接
            </button>
          )}
        </div>
      </div>
    </>
  );
}
