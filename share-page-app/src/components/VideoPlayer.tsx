import { useCallback, useEffect, useRef, useState } from "react";

interface VideoPlayerProps {
  src: string;
  streaming: boolean;
  duration?: number;
  onSeek?: (time: number) => void;
  onError?: (error: MediaError | null) => void;
}

const SPEED_OPTIONS = [0.5, 1, 1.5, 2] as const;

function formatTime(seconds: number): string {
  if (!isFinite(seconds) || seconds < 0) return "0:00";
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${s.toString().padStart(2, "0")}`;
}

export function VideoPlayer({
  src,
  streaming,
  duration: externalDuration,
  onSeek,
  onError,
}: VideoPlayerProps) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const progressRef = useRef<HTMLDivElement | null>(null);
  const [playing, setPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [bufferedEnd, setBufferedEnd] = useState(0);
  const [playbackRate, setPlaybackRate] = useState(1);
  const [dragging, setDragging] = useState(false);
  const draggingRef = useRef(false);

  const effectiveDuration = externalDuration && externalDuration > 0 ? externalDuration : duration;

  useEffect(() => {
    const v = videoRef.current;
    if (!v || !src) return;
    const tryPlay = () => { void v.play().catch(() => {}); };
    v.addEventListener("canplay", tryPlay, { once: true });
    return () => { v.removeEventListener("canplay", tryPlay); };
  }, [src]);

  useEffect(() => {
    const v = videoRef.current;
    if (!v) return;

    const onTimeUpdate = () => {
      if (!draggingRef.current) setCurrentTime(v.currentTime);
    };
    const onDurationChange = () => {
      if (isFinite(v.duration)) setDuration(v.duration);
    };
    const onProgress = () => {
      if (v.buffered.length > 0) {
        setBufferedEnd(v.buffered.end(v.buffered.length - 1));
      }
    };
    const onPlay = () => setPlaying(true);
    const onPause = () => setPlaying(false);
    const onErrorEvt = () => { onError?.(v.error); };

    v.addEventListener("timeupdate", onTimeUpdate);
    v.addEventListener("durationchange", onDurationChange);
    v.addEventListener("progress", onProgress);
    v.addEventListener("play", onPlay);
    v.addEventListener("pause", onPause);
    v.addEventListener("error", onErrorEvt);

    return () => {
      v.removeEventListener("timeupdate", onTimeUpdate);
      v.removeEventListener("durationchange", onDurationChange);
      v.removeEventListener("progress", onProgress);
      v.removeEventListener("play", onPlay);
      v.removeEventListener("pause", onPause);
      v.removeEventListener("error", onErrorEvt);
    };
  }, [onError]);

  const togglePlay = useCallback(() => {
    const v = videoRef.current;
    if (!v) return;
    if (v.paused) void v.play().catch(() => {});
    else v.pause();
  }, []);

  const changeSpeed = useCallback((rate: number) => {
    setPlaybackRate(rate);
    const v = videoRef.current;
    if (v) v.playbackRate = rate;
  }, []);

  const seekToPosition = useCallback(
    (clientX: number) => {
      const bar = progressRef.current;
      if (!bar || !effectiveDuration) return;
      const rect = bar.getBoundingClientRect();
      const ratio = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
      const target = ratio * effectiveDuration;
      setCurrentTime(target);
      return target;
    },
    [effectiveDuration],
  );

  const commitSeek = useCallback(
    (target: number) => {
      const v = videoRef.current;
      if (!v) return;

      if (streaming && onSeek) {
        const buffered = v.buffered;
        let inBuffer = false;
        for (let i = 0; i < buffered.length; i++) {
          if (target >= buffered.start(i) - 0.5 && target <= buffered.end(i) + 0.5) {
            inBuffer = true;
            break;
          }
        }
        if (inBuffer) {
          v.currentTime = target;
        } else {
          onSeek(target);
        }
      } else {
        v.currentTime = target;
      }
    },
    [streaming, onSeek],
  );

  const onProgressBarMouseDown = useCallback(
    (e: React.MouseEvent) => {
      e.preventDefault();
      setDragging(true);
      draggingRef.current = true;
      seekToPosition(e.clientX);

      const onMove = (ev: MouseEvent) => {
        seekToPosition(ev.clientX);
      };
      const onUp = (ev: MouseEvent) => {
        document.removeEventListener("mousemove", onMove);
        document.removeEventListener("mouseup", onUp);
        setDragging(false);
        draggingRef.current = false;
        const target = seekToPosition(ev.clientX);
        if (target !== undefined) commitSeek(target);
      };
      document.addEventListener("mousemove", onMove);
      document.addEventListener("mouseup", onUp);
    },
    [seekToPosition, commitSeek],
  );

  const onProgressBarTouchStart = useCallback(
    (e: React.TouchEvent) => {
      setDragging(true);
      draggingRef.current = true;
      const touch = e.touches[0];
      seekToPosition(touch.clientX);

      const onMove = (ev: TouchEvent) => {
        ev.preventDefault();
        seekToPosition(ev.touches[0].clientX);
      };
      const onEnd = (ev: TouchEvent) => {
        document.removeEventListener("touchmove", onMove);
        document.removeEventListener("touchend", onEnd);
        setDragging(false);
        draggingRef.current = false;
        const changedTouch = ev.changedTouches[0];
        const target = seekToPosition(changedTouch.clientX);
        if (target !== undefined) commitSeek(target);
      };
      document.addEventListener("touchmove", onMove, { passive: false });
      document.addEventListener("touchend", onEnd);
    },
    [seekToPosition, commitSeek],
  );

  const progressPercent =
    effectiveDuration > 0 ? (currentTime / effectiveDuration) * 100 : 0;
  const bufferedPercent =
    effectiveDuration > 0 ? (bufferedEnd / effectiveDuration) * 100 : 0;

  return (
    <div className="mb-4">
      <video
        ref={videoRef}
        className="w-full rounded-t-xl bg-black cursor-pointer"
        src={src}
        playsInline
        onClick={togglePlay}
      />

      {/* Controls container */}
      <div className="bg-slate-900 rounded-b-xl px-3 py-2.5 space-y-2">
        {/* Progress bar */}
        <div
          ref={progressRef}
          className="relative h-5 flex items-center cursor-pointer group"
          onMouseDown={onProgressBarMouseDown}
          onTouchStart={onProgressBarTouchStart}
        >
          <div className="absolute inset-x-0 h-1 bg-slate-700 rounded-full group-hover:h-1.5 transition-all">
            {/* Buffered */}
            <div
              className="absolute inset-y-0 left-0 bg-slate-500 rounded-full"
              style={{ width: `${Math.min(100, bufferedPercent)}%` }}
            />
            {/* Played */}
            <div
              className="absolute inset-y-0 left-0 bg-indigo-500 rounded-full"
              style={{ width: `${Math.min(100, progressPercent)}%` }}
            />
          </div>
          {/* Thumb */}
          <div
            className={`absolute w-3 h-3 bg-indigo-400 rounded-full -translate-x-1/2 transition-transform ${
              dragging ? "scale-125" : "scale-100 group-hover:scale-110"
            }`}
            style={{ left: `${Math.min(100, progressPercent)}%` }}
          />
        </div>

        {/* Time + controls row */}
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={togglePlay}
            className="text-white hover:text-indigo-300 transition-colors"
          >
            {playing ? (
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fillRule="evenodd"
                  d="M5 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1H6a1 1 0 01-1-1V4zm7 0a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z"
                  clipRule="evenodd"
                />
              </svg>
            ) : (
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fillRule="evenodd"
                  d="M6.3 2.841A1.5 1.5 0 004 4.11v11.78a1.5 1.5 0 002.3 1.269l9.344-5.89a1.5 1.5 0 000-2.538L6.3 2.84z"
                  clipRule="evenodd"
                />
              </svg>
            )}
          </button>

          <span className="text-xs text-slate-300 tabular-nums min-w-[80px]">
            {formatTime(currentTime)} / {formatTime(effectiveDuration)}
          </span>

          <div className="flex-1" />

          {/* Speed controls */}
          <div className="flex items-center gap-1">
            {SPEED_OPTIONS.map((rate) => (
              <button
                key={rate}
                type="button"
                onClick={() => changeSpeed(rate)}
                className={`px-2 py-0.5 rounded text-[11px] font-medium transition-colors ${
                  playbackRate === rate
                    ? "bg-indigo-600 text-white"
                    : "text-slate-400 hover:text-white"
                }`}
              >
                {rate}x
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
