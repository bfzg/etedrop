import { useEffect, useMemo, useRef } from "react";
import Player from "xgplayer";
import "xgplayer/dist/index.min.css";

interface VideoPlayerProps {
  src: string;
  streaming: boolean;
  duration?: number;
  onSeek?: (time: number) => void;
  onPlaybackTime?: (time: number) => void;
  onError?: (error: MediaError | null) => void;
}

const PLAYBACK_RATES = [0.5, 0.75, 1, 1.25, 1.5, 2] as const;

function isInBufferedRange(media: HTMLMediaElement, t: number) {
  const b = media.buffered;
  for (let i = 0; i < b.length; i++) {
    if (t >= b.start(i) - 0.5 && t <= b.end(i) + 0.5) return true;
  }
  return false;
}

export function VideoPlayer({ src, streaming, onSeek, onPlaybackTime, onError }: VideoPlayerProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const playerRef = useRef<Player | null>(null);
  const lastGoodTimeRef = useRef(0);
  const streamingRef = useRef(streaming);
  const onSeekRef = useRef(onSeek);
  const onPlaybackTimeRef = useRef<VideoPlayerProps["onPlaybackTime"]>(undefined);
  const onErrorRef = useRef(onError);

  useEffect(() => {
    streamingRef.current = streaming;
    onSeekRef.current = onSeek;
    onPlaybackTimeRef.current = onPlaybackTime;
    onErrorRef.current = onError;
  });

  const playbackRateList = useMemo(() => [...PLAYBACK_RATES], []);

  useEffect(() => {
    const el = containerRef.current;
    if (!el || !src) return;

    const player = new Player({
      el,
      url: src,
      autoplay: true,
      playsinline: true,
      fluid: true,
      playbackRate: playbackRateList,
    });

    playerRef.current = player;

    const media = player.media as HTMLVideoElement | undefined;
    if (media) {
      const onTimeUpdate = () => {
        if (Number.isFinite(media.currentTime)) {
          lastGoodTimeRef.current = media.currentTime;
          onPlaybackTimeRef.current?.(media.currentTime);
        }
      };
      const onSeeking = () => {
        if (!streamingRef.current || !onSeekRef.current) return;
        const target = media.currentTime;
        if (!Number.isFinite(target)) return;

        if (!isInBufferedRange(media, target)) {
          onSeekRef.current(target);
        }
      };
      const onErrorEvt = () => onErrorRef.current?.(media.error);

      media.addEventListener("timeupdate", onTimeUpdate);
      media.addEventListener("seeking", onSeeking);
      media.addEventListener("error", onErrorEvt);

      return () => {
        media.removeEventListener("timeupdate", onTimeUpdate);
        media.removeEventListener("seeking", onSeeking);
        media.removeEventListener("error", onErrorEvt);
        player.destroy();
        playerRef.current = null;
      };
    }

    return () => {
      player.destroy();
      playerRef.current = null;
    };
  }, [src, playbackRateList]);

  return (
    <div className="mb-4">
      <div
        ref={containerRef}
        className="w-full overflow-hidden rounded-xl bg-black"
      />
    </div>
  );
}
