import 'dart:io';

/// 缓存 ffmpeg 能力探测（pipe 协议、libx264），避免重复启动子进程。
class ShareP2pFfmpegCapabilities {
  bool? pipeProtocolSupported;
  bool? libx264Supported;

  Future<bool> ensurePipeProtocolSupported(String ffmpegPath) async {
    if (pipeProtocolSupported != null) return pipeProtocolSupported!;
    try {
      final res = await Process.run(ffmpegPath, [
        '-protocols',
      ], stdoutEncoding: const SystemEncoding());
      final stdout = (res.stdout ?? '').toString();
      final hasPipe = stdout
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .any((e) => e == 'pipe');
      pipeProtocolSupported = res.exitCode == 0 ? hasPipe : true;
      if (stdout.trim().isEmpty) {
        pipeProtocolSupported = true;
      }
    } catch (_) {
      pipeProtocolSupported = true;
    }
    // ignore: avoid_print
    print('[ShareP2P] ffmpeg pipe protocol supported: $pipeProtocolSupported');
    return pipeProtocolSupported!;
  }

  Future<bool> ensureLibx264Supported(String ffmpegPath) async {
    if (libx264Supported != null) return libx264Supported!;
    try {
      final res = await Process.run(ffmpegPath, [
        '-encoders',
      ], stdoutEncoding: const SystemEncoding());
      final stdout = (res.stdout ?? '').toString();
      libx264Supported = stdout.contains(' libx264 ');
    } catch (_) {
      libx264Supported = false;
    }
    // ignore: avoid_print
    print('[ShareP2P] ffmpeg libx264 supported: $libx264Supported');
    return libx264Supported!;
  }

  void reset() {
    pipeProtocolSupported = null;
    libx264Supported = null;
  }
}
