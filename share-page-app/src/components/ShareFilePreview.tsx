import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { VideoPlayer } from "./VideoPlayer";
import { getSharePreviewKind } from "../utils/shareFilePreviewKind";

const DEFAULT_MAX_TEXT_PREVIEW_BYTES = 2 * 1024 * 1024;

interface ShareFilePreviewProps {
  fileName: string;
  /** 视频为 MSE / blob URL；其它类型为整文件下载完成后的 blob URL */
  mediaUrl: string;
  streaming: boolean;
  streamDuration?: number;
  fileSize?: number;
  maxTextPreviewBytes?: number;
  onSeek?: (time: number) => void;
  onPlaybackTime?: (time: number) => void;
  onVideoError?: (error: MediaError | null) => void;
}

export function ShareFilePreview({
  fileName,
  mediaUrl,
  streaming,
  streamDuration,
  fileSize,
  maxTextPreviewBytes = DEFAULT_MAX_TEXT_PREVIEW_BYTES,
  onSeek,
  onPlaybackTime,
  onVideoError,
}: ShareFilePreviewProps) {
  const { t } = useTranslation();
  const inferredKind = getSharePreviewKind(fileName);
  const kind =
    inferredKind === "none" && streaming && mediaUrl
      ? "video"
      : inferredKind;
  const [textBody, setTextBody] = useState("");
  const [textError, setTextError] = useState("");

  useEffect(() => {
    if (kind === "pdf" || kind === "image") {
      if (mediaUrl) {
        window.open(mediaUrl, "_blank");
      }
    }
  }, [kind, mediaUrl]);

  useEffect(() => {
    if (kind !== "text" || !mediaUrl) {
      setTextBody("");
      setTextError("");
      return;
    }
    if (fileSize != null && fileSize > maxTextPreviewBytes) {
      setTextBody("");
      setTextError(t("share.previewTextTooLarge"));
      return;
    }

    let cancelled = false;
    setTextError("");
    setTextBody("");

    void fetch(mediaUrl)
      .then((r) => {
        if (!r.ok) throw new Error(String(r.status));
        return r.text();
      })
      .then((body) => {
        if (!cancelled) setTextBody(body);
      })
      .catch(() => {
        if (!cancelled) setTextError(t("share.previewTextFailed"));
      });

    return () => {
      cancelled = true;
    };
  }, [kind, mediaUrl, fileSize, maxTextPreviewBytes, t]);

  if (!mediaUrl) return null;

  if (kind === "video") {
    return (
      <VideoPlayer
        src={mediaUrl}
        streaming={streaming}
        duration={streamDuration}
        onSeek={onSeek}
        onPlaybackTime={onPlaybackTime}
        onError={onVideoError}
      />
    );
  }

  if (kind === "image" || kind === "pdf") {
    return (
      <div className="mb-4 rounded-xl p-4 bg-blue-50 border border-blue-100 text-center">
        <p className="text-sm text-blue-800 font-medium mb-2">
          {kind === "pdf" ? "PDF" : "图片"}已准备就绪
        </p>
        <button
          type="button"
          onClick={() => window.open(mediaUrl, "_blank")}
          className="text-xs font-bold text-[#0052D9] hover:underline"
        >
          点击此处在新标签页打开
        </button>
      </div>
    );
  }

  if (kind === "audio") {
    return (
      <div className="mb-4 rounded-xl p-4 bg-slate-50 border border-slate-200/80">
        <audio src={mediaUrl} controls className="w-full" />
      </div>
    );
  }

  if (kind === "text") {
    if (textError) {
      return (
        <div className="mb-4 rounded-xl px-3 py-2 text-sm text-amber-900 bg-amber-50 border border-amber-100">
          {textError}
        </div>
      );
    }
    return (
      <div className="mb-4 rounded-xl border border-slate-200/80 bg-white overflow-hidden">
        <pre className="text-[13px] leading-relaxed p-3 max-h-[min(70vh,480px)] overflow-auto whitespace-pre-wrap wrap-break-word font-mono text-slate-800">
          {textBody}
        </pre>
      </div>
    );
  }

  return null;
}
