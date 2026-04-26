import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import type { DataChannelMessage } from "../types";
import { ensureMetaMatchesOrClear, getOpfsPartialSize, readSessionMeta } from "../utils/shareDownloadStorage";
import { shouldUseOpfsResumeFromPartial } from "../utils/downloadSink";
import { useSignaling } from "./useSignaling";
import { useDownload, type DownloadIntent } from "./useDownload";
import { useStreamPlayer } from "./useStreamPlayer";

export function useSharePage(deviceId: string, shareCode: string) {
  const { t } = useTranslation();
  const [fileInfo, setFileInfo] = useState<{
    fileName: string;
    fileSize: number;
    hasPassword: boolean;
  } | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [passwordError, setPasswordError] = useState("");
  const [verifyLoading, setVerifyLoading] = useState(false);
  const [showDownloadBtn, setShowDownloadBtn] = useState(false);
  /** 流式播放中途 DC 断开时仅自动整网重连一次，避免循环 */
  const streamAutoReconnectPendingRef = useRef(false);
  /** 持有 setTimeout 句柄，方便在新连接建好或被卸载时取消等待中的重连。 */
  const streamAutoReconnectTimerRef = useRef<number | null>(null);

  const signaling = useSignaling(deviceId, shareCode);

  const download = useDownload(deviceId, shareCode, signaling.sendJson);

  const onStreamEnd = useCallback(() => {
    download.setShowProgress(false);
    download.setShowDone(true);
    download.setDoneKind("stream");
  }, [download]);

  const stream = useStreamPlayer(
    signaling.sendJson,
    signaling.setStatusState,
    signaling.setShowReconnect,
    onStreamEnd,
  );

  // Register the DataChannel message router
  useEffect(() => {
    signaling.setDcMessageHandler((ev: MessageEvent) => {
      // Handle DC close
      if (ev.data === "__dc_close__") {
        if (!download.downloadCompletedRef.current) {
          signaling.setStatusState("error", t("p2p.disconnected"));
          signaling.setShowReconnect(true);
          const wasStreaming =
            stream.streamingActiveRef.current ||
            stream.streamModeRef.current === "mse-fmp4";
          if (
            wasStreaming &&
            !streamAutoReconnectPendingRef.current
          ) {
            streamAutoReconnectPendingRef.current = true;
            if (streamAutoReconnectTimerRef.current != null) {
              window.clearTimeout(streamAutoReconnectTimerRef.current);
            }
            streamAutoReconnectTimerRef.current = window.setTimeout(() => {
              streamAutoReconnectTimerRef.current = null;
              streamAutoReconnectPendingRef.current = false;
              if (download.downloadCompletedRef.current) return;
              // 在 900ms 等待期间如果新的 DC 已经成功打开，就别再触发整网 reconnect，
              // 否则会把刚刚建好的链接再拆掉，进入 dc.close → dispatch __dc_close__
              // → schedule reconnect 的死循环。
              if (
                signaling.dc.current &&
                signaling.dc.current.readyState === "open"
              ) {
                return;
              }
              signaling.reconnect();
            }, 900);
          }
        }
        return;
      }

      if (typeof ev.data === "string") {
        try {
          const m = JSON.parse(ev.data) as DataChannelMessage;
          switch (m.type) {
            case "share-info":
              void ensureMetaMatchesOrClear(deviceId, shareCode, m.fileName, m.fileSize);
              setFileInfo({
                fileName: m.fileName,
                fileSize: m.fileSize,
                hasPassword: !!m.hasPassword,
              });
              download.handleShareInfo({
                fileName: m.fileName,
                fileSize: m.fileSize,
                hasPassword: !!m.hasPassword,
              });
              signaling.setShowStatusBar(false);
              if (m.hasPassword) {
                setShowPassword(true);
                setShowDownloadBtn(false);
              } else {
                setShowPassword(false);
                setShowDownloadBtn(true);
              }
              break;
            case "error":
              signaling.setStatusState("error", m.message || t("errors.unknown"));
              signaling.setShowReconnect(true);
              break;
            case "verify-result":
              if (m.success) {
                setShowPassword(false);
                setPasswordError("");
                setShowDownloadBtn(true);
              } else {
                setPasswordError(m.error || t("errors.passwordWrong"));
                setVerifyLoading(false);
              }
              break;
            case "file-meta":
              download.handleFileMeta(m);
              setShowDownloadBtn(false);
              break;
            case "file-done":
              download.downloadCompletedRef.current = true;
              void download.finishDownload();
              break;
            case "stream-meta":
              stream.handleStreamMeta(m);
              break;
            case "stream-seeked":
              stream.handleStreamSeeked(typeof m.actualTime === "number" ? m.actualTime : undefined);
              break;
            case "stream-done":
              download.downloadCompletedRef.current = true;
              stream.handleStreamDone();
              break;
          }
        } catch { /* ignore */ }
      } else {
        const buf = ev.data as ArrayBuffer;

        if (stream.streamModeRef.current === "mse-fmp4") {
          stream.handleStreamBinary(buf);
          download.setProgress((p: { received: number; total: number }) => ({
            received: p.received + buf.byteLength,
            total: p.total || download.totalBytesRef.current || 1,
          }));
          return;
        }

        download.handleBinaryChunk(buf);
      }
    });
  }, [deviceId, shareCode, signaling, download, stream, t]);

  useEffect(() => {
    return () => {
      if (streamAutoReconnectTimerRef.current != null) {
        window.clearTimeout(streamAutoReconnectTimerRef.current);
        streamAutoReconnectTimerRef.current = null;
      }
      streamAutoReconnectPendingRef.current = false;
    };
  }, []);

  const sendVerify = useCallback(async (password: string) => {
    try {
      await signaling.ensureP2PReady();
    } catch {
      setVerifyLoading(false);
      return;
    }
    setVerifyLoading(true);
    setPasswordError("");
    signaling.sendJson({ type: "share-verify", password });
  }, [signaling]);

  const sendDownloadStart = useCallback(async (opts?: {
    intent?: DownloadIntent;
    remuxFmp4?: boolean;
    stream?: boolean;
  }) => {
    try {
      await signaling.ensureP2PReady();
    } catch {
      return;
    }
    // Reset download state on each user action so mobile browsers don't get stuck
    // due to leftover queues/writers/paused state from the previous attempt.
    download.resetDownload();
    download.downloadIntentRef.current = opts?.intent ?? "download";

    if (opts?.stream) {
      streamAutoReconnectPendingRef.current = false;
      if (streamAutoReconnectTimerRef.current != null) {
        window.clearTimeout(streamAutoReconnectTimerRef.current);
        streamAutoReconnectTimerRef.current = null;
      }
      // Allow playing multiple stream sessions in one page lifecycle.
      // After the first stream ends, MediaSource/SourceBuffer may remain in an ended state.
      // Reset first so a new MediaSource is created.
      stream.resetStream();
      stream.startMse();
      signaling.sendJson({
        type: "stream-start",
        remuxFmp4: !!opts?.remuxFmp4,
      });
      setShowDownloadBtn(false);
      download.setShowProgress(true);
      return;
    }

    let resume = 0;
    const fi = download.fileInfoRef.current;
    if (fi && shouldUseOpfsResumeFromPartial()) {
      const meta = readSessionMeta(deviceId, shareCode);
      if (meta && meta.fileName === fi.fileName && meta.fileSize === fi.fileSize) {
        resume = await getOpfsPartialSize(deviceId, shareCode);
        if (resume > fi.fileSize) resume = fi.fileSize;
      }
    }
    signaling.sendJson({
      type: "download-start",
      resumeFrom: resume,
      remuxFmp4: !!opts?.remuxFmp4,
    });
  }, [deviceId, shareCode, signaling, download, stream]);

  return {
    status: signaling.status,
    showStatusBar: signaling.showStatusBar,
    showReconnect: signaling.showReconnect,
    reconnect: signaling.reconnect,
    fileInfo,
    showPassword,
    passwordError,
    verifyLoading,
    showDownloadBtn,
    showProgress: download.showProgress,
    progress: download.progress,
    showDone: download.showDone,
    doneKind: download.doneKind,
    resumeHintBytes: download.resumeHintBytes,
    playUrl: download.playUrl,
    downloadError: download.downloadError,
    mseUrl: stream.mseUrl,
    streaming: stream.streaming,
    streamDuration: stream.streamDuration,
    sendVerify,
    sendDownloadStart,
    sendSeek: stream.sendSeek,
    setPlaybackTime: stream.setPlaybackTime,
  };
}
