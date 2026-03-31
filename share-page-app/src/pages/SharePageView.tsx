import { useState } from "react";
import { useParams } from "react-router-dom";
import { useSharePage } from "../hooks/useSharePage";
import { formatBytes } from "../utils/format";
import { FileIconSvg } from "../components/fileIconSvgComponent";
import { VideoPlayer } from "../components/VideoPlayer";

const VIDEO_EXTS = new Set(["mp4", "m4v", "mov", "webm", "ogv"]);

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
  } = useSharePage(deviceId, shareCode);

  const videoSrc = mseUrl || playUrl;

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
    <div className="min-h-screen flex items-center justify-center p-5">
      <div className="max-w-[440px] w-full">
        <div className="text-2xl font-bold text-gray-800 mb-1">Eddy</div>
        <p className="text-[13px] text-gray-500 mb-6">分享码: {shareCode}</p>

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
            <button
              type="button"
              disabled={!fileInfo || !isLikelyVideo(fileInfo.fileName)}
              onClick={() => {
                void sendDownloadStart({
                  intent: "play",
                  remuxFmp4: true,
                  stream: true,
                });
              }}
              className="flex items-center justify-center gap-1.5 py-3 px-6 rounded-lg text-[15px] font-medium bg-indigo-600 text-white cursor-pointer w-full hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              播放
            </button>

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
          </div>
        )}

        {showProgress && (
          <div className="mt-4">
            <div className="text-xs text-slate-500 text-center">
              {formatBytes(progress.received)} / {formatBytes(progress.total)} (
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
  );
}
