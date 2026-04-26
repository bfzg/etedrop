/// fMP4 在线播放策略（remux vs transcode）。
///
/// 这里只描述「ffmpeg 应该用什么参数 / 浏览器需要什么 mime」，
/// 不依赖 flutter_webrtc / Process / Storage —— 方便单独测试与扩展。
///
/// 调度（启动 ffmpeg、读取 stdout、按 fMP4 box 切片、走 DataChannel 背压）
/// 仍由 `share_p2p_handler.dart` 负责。
library;

const int kHighRes4kWidth = 3840;
const int kHighRes4kHeight = 2160;

/// 仅 mp4/m4v/mov 在 ffprobe 无法探测到 codec 时才假设兼容；
/// webm/mkv/avi/wmv 等格式探测失败通常意味着 VP9 / Opus 等不兼容编码，
/// 此时强制走转码，避免 `-c copy` 把不兼容编码塞进 mp4 容器导致输出空。
const Set<String> kNativeCompatExtensions = {'mp4', 'm4v', 'mov'};

/// 每次开播或 seek 重启前由 ffprobe 读出来的容器/编码信息。
class VideoStreamProbe {
  final String? videoCodec;
  final String? audioCodec;
  final int? width;
  final int? height;
  final double? duration;
  final String fileExtensionLower;

  const VideoStreamProbe({
    required this.videoCodec,
    required this.audioCodec,
    required this.width,
    required this.height,
    required this.duration,
    required this.fileExtensionLower,
  });

  bool get isHighRes4k =>
      (width != null && width! >= kHighRes4kWidth) ||
      (height != null && height! >= kHighRes4kHeight);
}

/// fMP4 在线播放策略基类。
///
/// 由 [VideoStreamPlanner.plan] 根据 [VideoStreamProbe] 自动挑选实现。
sealed class VideoStreamPlan {
  final VideoStreamProbe probe;

  /// 浏览器 MSE 创建 SourceBuffer 所需 mime（含 codecs）。
  final String mime;

  /// 仅 codecs 部分（与 [mime] 内的一致），用于 stream-meta 单独下发。
  final List<String> codecParts;

  /// `-re` 实时输入：源端按媒体时间锁速读，避免 4K 这种大码率瞬间灌满 DC/SCTP，
  /// 进而触发 ICE consent 抖动 → 浏览器端 dc.close → 全链路重连循环。
  final bool useRealtimeInputPacing;

  const VideoStreamPlan({
    required this.probe,
    required this.mime,
    required this.codecParts,
    required this.useRealtimeInputPacing,
  });

  bool get needsTranscode;

  /// 仅 transcode 策略可能为 true：4K 源会自动 `scale=-2:1080`。
  bool get downscaleForHighRes4k;

  /// 调度器决定具体输出位置（pipe 或临时文件）后调用，得到 ffmpeg 完整 argv。
  ///
  /// [seekTime] 仅在用户拖动进度条触发的 seek 重启时传入。
  List<String> buildFfmpegArgs({
    required String inputPath,
    required bool usePipe,
    required String? tempOutputPath,
    double? seekTime,
  });

  /// 单行可读描述，用于诊断日志。
  String describe();
}

/// `-c copy` 一份原编码切片为 fMP4。
///
/// 编码已是 H.264 / HEVC + AAC 时 CPU 占用极低；
/// 但读速默认无限制——4K 的 50Mbps+ 码率 + 不限速 → 用 `-re` 锁速。
class RemuxVideoStreamPlan extends VideoStreamPlan {
  const RemuxVideoStreamPlan({
    required super.probe,
    required super.mime,
    required super.codecParts,
    required super.useRealtimeInputPacing,
  });

  @override
  bool get needsTranscode => false;

  @override
  bool get downscaleForHighRes4k => false;

  @override
  List<String> buildFfmpegArgs({
    required String inputPath,
    required bool usePipe,
    required String? tempOutputPath,
    double? seekTime,
  }) {
    return <String>[
      '-hide_banner', '-loglevel', 'error',
      if (useRealtimeInputPacing) '-re',
      '-i', inputPath,
      '-map', '0',
      '-c', 'copy',
      if (seekTime != null) ...[
        // copy 模式下把 -ss 放在输入后，避免把时间锚点固定到上一个关键帧，
        // 减少 seek 后浏览器时间轴错位导致「卡住不播」。
        '-ss', seekTime.toStringAsFixed(3),
      ],
      '-movflags', '+frag_keyframe+empty_moov+default_base_moof',
      '-f', 'mp4',
      if (usePipe) 'pipe:1' else ...['-y', tempOutputPath!],
    ];
  }

  @override
  String describe() =>
      'remux(c=copy${useRealtimeInputPacing ? ", -re" : ""})';
}

/// libx264 + AAC 重编码；4K 源会自动 `scale=-2:1080` 降码率到 1080p。
///
/// CPU 已经是瓶颈，因此默认不再叠加 `-re`（双重限速反而让转码器空等）。
class TranscodeVideoStreamPlan extends VideoStreamPlan {
  @override
  final bool downscaleForHighRes4k;

  const TranscodeVideoStreamPlan({
    required super.probe,
    required super.mime,
    required super.codecParts,
    required super.useRealtimeInputPacing,
    required this.downscaleForHighRes4k,
  });

  @override
  bool get needsTranscode => true;

  @override
  List<String> buildFfmpegArgs({
    required String inputPath,
    required bool usePipe,
    required String? tempOutputPath,
    double? seekTime,
  }) {
    return <String>[
      '-hide_banner', '-loglevel', 'error',
      if (useRealtimeInputPacing) '-re',
      // 转码模式下 `-ss` 放在输入前更精确（基于解复用时间），seek 体验更好；
      // 起播没有 seek 时不传该参数。
      if (seekTime != null) ...['-ss', seekTime.toStringAsFixed(3)],
      '-i', inputPath,
      '-map', '0:v:0',
      '-map', '0:a:0?',
      '-c:v', 'libx264',
      '-preset', 'veryfast',
      '-crf', '23',
      if (downscaleForHighRes4k) ...[
        '-vf', 'scale=-2:1080',
        '-maxrate', '4M',
        '-bufsize', '8M',
      ],
      '-c:a', 'aac',
      '-b:a', '128k',
      '-movflags', '+frag_keyframe+empty_moov+default_base_moof',
      '-f', 'mp4',
      if (usePipe) 'pipe:1' else ...['-y', tempOutputPath!],
    ];
  }

  @override
  String describe() =>
      'transcode(libx264+aac${downscaleForHighRes4k ? "+1080p" : ""}'
      '${useRealtimeInputPacing ? ", -re" : ""})';
}

/// 由 ffprobe 信息选择具体策略。
class VideoStreamPlanner {
  /// 是否需要走转码路径（视频或音频编码不兼容浏览器 MSE）。
  static bool requiresTranscode(VideoStreamProbe probe) {
    final v = probe.videoCodec;
    final a = probe.audioCodec;
    final vOk = v == 'h264' ||
        v == 'hevc' ||
        (v == null && kNativeCompatExtensions.contains(probe.fileExtensionLower));
    final aOk = a == null || a == 'aac';
    return !vOk || !aOk;
  }

  /// 构建播放计划（不会启动 ffmpeg；只确定参数模板与 mime）。
  static VideoStreamPlan plan(VideoStreamProbe probe) {
    if (requiresTranscode(probe)) {
      return TranscodeVideoStreamPlan(
        probe: probe,
        mime: 'video/mp4; codecs="avc1.42E01E, mp4a.40.2"',
        codecParts: const ['avc1.42E01E', 'mp4a.40.2'],
        // CPU 已是天花板；叠加 -re 反而让转码器空等。
        useRealtimeInputPacing: false,
        downscaleForHighRes4k: probe.isHighRes4k,
      );
    }
    final v = probe.videoCodec == 'hevc' ? 'hev1.1.6.L93.B0' : 'avc1.42E01E';
    final parts = <String>[v];
    if (probe.audioCodec == 'aac') parts.add('mp4a.40.2');
    return RemuxVideoStreamPlan(
      probe: probe,
      mime: 'video/mp4; codecs="${parts.join(', ')}"',
      codecParts: parts,
      // 高分辨率 copy 仍按实时锁速，避免开播一瞬间把整个 mp4 灌入网络打爆 SCTP / DC。
      useRealtimeInputPacing: probe.isHighRes4k,
    );
  }
}
