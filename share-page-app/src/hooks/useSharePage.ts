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
  /** 「断流续播」：DC 重连后下一次收到 share-info 时自动重发 stream-start
   *  并附带 resumeFrom，让 sender 端从断点继续推流。 */
  const streamResumePendingRef = useRef(false);
  /** 续播起点（秒），DC 关闭瞬间从 useStreamPlayer.getResumeTime() 抓取。 */
  const streamResumeFromRef = useRef(0);
  /** 上次 stream-start 是否要求 remuxFmp4，重连后续播保持一致。 */
  const streamLastRemuxRef = useRef(false);

  const signaling = useSignaling(deviceId, shareCode);

  const download = useDownload(deviceId, shareCode, signaling.sendJson);

  const onStreamEnd = useCallback(() => {
    const fi = download.fileInfoRef.current;
    const total = download.totalBytesRef.current || fi?.fileSize || 0;
    if (total > 0) {
      download.setProgress({ received: total, total });
    }
    download.setShowProgress(false);
    download.setShowDone(true);
    download.setDoneKind("stream");
  }, [download]);

  const onStreamMediaAppended = useCallback(
    (appendedTotal: number) => {
      const fi = download.fileInfoRef.current;
      const streamTotal = download.totalBytesRef.current || fi?.fileSize || 0;
      download.setProgress({ received: appendedTotal, total: streamTotal });
    },
    [download],
  );

  const stream = useStreamPlayer(
    signaling.sendJson,
    signaling.setStatusState,
    signaling.setShowReconnect,
    onStreamEnd,
    onStreamMediaAppended,
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
            // 抓取断开瞬间的 currentTime 作为续播起点；新连接 share-info 回来后
            // 由下方分支自动 sendJson({ type: "stream-start", resumeFrom })。
            const resumeFrom = stream.getResumeTime();
            streamResumeFromRef.current = resumeFrom;
            streamResumePendingRef.current = true;
            console.log("[fastsend] stream auto-resume armed", {
              resumeFrom,
              remuxFmp4: streamLastRemuxRef.current,
            });

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
              // 「断流续播」：重连后第一次收到 share-info 说明 sender 已就绪。
              // 直接重发 stream-start with resumeFrom，sender 用 -ss 从断点重启，
              // 网页端会在 stream-meta(resume:true) 分支里复用既有 SourceBuffer。
              // 有密码场景这里不自动续播——sender 重新初始化后 _passwordVerified
              // 已经回到 false，直接发 stream-start 会被回 AUTH_REQUIRED。
              if (
                streamResumePendingRef.current &&
                !m.hasPassword &&
                stream.streamingActiveRef.current
              ) {
                streamResumePendingRef.current = false;
                const resumeFrom = streamResumeFromRef.current;
                streamResumeFromRef.current = 0;
                console.log("[fastsend] stream auto-resume → stream-start", {
                  resumeFrom,
                  remuxFmp4: streamLastRemuxRef.current,
                });
                signaling.setShowReconnect(false);
                signaling.sendJson({
                  type: "stream-start",
                  remuxFmp4: streamLastRemuxRef.current,
                  resumeFrom,
                });
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
      streamResumePendingRef.current = false;
      streamResumeFromRef.current = 0;
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
      streamResumePendingRef.current = false;
      streamResumeFromRef.current = 0;
      if (streamAutoReconnectTimerRef.current != null) {
        window.clearTimeout(streamAutoReconnectTimerRef.current);
        streamAutoReconnectTimerRef.current = null;
      }
      // 记下本次 remuxFmp4，自动续播时沿用同一参数，避免对端切到不同的 plan。
      streamLastRemuxRef.current = !!opts?.remuxFmp4;
      // Allow playing multiple stream sessions in one page lifecycle.
      // After the first stream ends, MediaSource/SourceBuffer may remain in an ended state.
      // Reset first so a new MediaSource is created.
      stream.resetStream();
      stream.startMse();
      const fi = download.fileInfoRef.current;
      if (fi && fi.fileSize > 0) {
        download.totalBytesRef.current = fi.fileSize;
        download.setProgress({ received: 0, total: fi.fileSize });
      }
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

  const sendSeek = useCallback(
    (targetTime: number) => {
      const fi = download.fileInfoRef.current;
      const total = fi?.fileSize ?? download.totalBytesRef.current ?? 0;
      if (total > 0) {
        download.setProgress({ received: 0, total });
      }
      stream.sendSeek(targetTime);
    },
    [download, stream],
  );

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
    sendSeek,
    setPlaybackTime: stream.setPlaybackTime,
  };
}
