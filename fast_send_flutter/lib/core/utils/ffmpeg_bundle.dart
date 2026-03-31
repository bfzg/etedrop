import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FfmpegBundle {
  static const _assetBase = 'assets/ffmpeg';

  static bool get isSupportedPlatform => Platform.isWindows || Platform.isMacOS;

  static String _platformSegment() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    throw UnsupportedError('Unsupported platform for ffmpeg bundle');
  }

  static String _ffmpegName() => Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
  static String _ffprobeName() =>
      Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

  static Future<Directory> _ensureInstallDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'ffmpeg'));
    await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _writeIfMissing({
    required String assetPath,
    required String outPath,
    bool executable = false,
  }) async {
    final out = File(outPath);

    // 读取打包内的资源；如果目标文件已存在且内容一致则跳过，否则覆盖写入。
    // 这样可以避免升级 ffmpeg 后仍继续使用旧版本（甚至损坏/架构不匹配）的落地副本。
    final ByteData data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    if (await out.exists()) {
      try {
        final len = await out.length();
        if (len == bytes.length && len > 0) {
          final existing = await out.readAsBytes();
          if (existing.length == bytes.length) {
            var same = true;
            for (var i = 0; i < bytes.length; i++) {
              if (existing[i] != bytes[i]) {
                same = false;
                break;
              }
            }
            if (same) return out;
          }
        }
      } catch (_) {
        // Best-effort: if read/compare fails, fall through to overwrite.
      }
    }

    await out.parent.create(recursive: true);
    await out.writeAsBytes(
      bytes,
      flush: true,
    );

    if (executable && !Platform.isWindows) {
      try {
        await Process.run('chmod', ['+x', out.path]);
      } catch (_) {
        // Best-effort. If this fails, Process.start will fail later and surface error.
      }
    }
    return out;
  }

  static Future<({String ffmpegPath, String ffprobePath})>
  ensureExtracted() async {
    if (!isSupportedPlatform) {
      throw UnsupportedError('FFmpeg bundle is not available on this platform');
    }

    final dir = await _ensureInstallDir();
    final seg = _platformSegment();

    final ffmpegAsset = '$_assetBase/$seg/${_ffmpegName()}';
    final ffprobeAsset = '$_assetBase/$seg/${_ffprobeName()}';

    final ffmpegOut = p.join(dir.path, _ffmpegName());
    final ffprobeOut = p.join(dir.path, _ffprobeName());

    final ffmpeg = await _writeIfMissing(
      assetPath: ffmpegAsset,
      outPath: ffmpegOut,
      executable: true,
    );
    final ffprobe = await _writeIfMissing(
      assetPath: ffprobeAsset,
      outPath: ffprobeOut,
      executable: true,
    );

    return (ffmpegPath: ffmpeg.path, ffprobePath: ffprobe.path);
  }
}
