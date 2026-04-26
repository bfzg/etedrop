import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ffmpeg_bundle.dart';
import 'transfer_temp_cache.dart';

class FfmpegRunner {
  FfmpegRunner();

  Future<File> remuxToFragmentedMp4({
    required String inputPath,
    String? outputFileName,
  }) async {
    if (!FfmpegBundle.isSupportedPlatform) {
      throw UnsupportedError(
        'FFmpeg runner is not available on this platform',
      );
    }

    final bins = await FfmpegBundle.ensureExtracted();

    final tmpDir = await ensureTransferTempSubdirectory('ffmpeg');
    final baseName = outputFileName ??
        '${p.basenameWithoutExtension(inputPath)}.fmp4.mp4';
    final outPath = p.join(tmpDir.path, baseName);

    final args = <String>[
      '-hide_banner',
      '-loglevel',
      'error',
      '-y',
      '-i',
      inputPath,
      '-map',
      '0',
      '-c',
      'copy',
      '-movflags',
      '+frag_keyframe+empty_moov+default_base_moof',
      '-f',
      'mp4',
      outPath,
    ];

    final res = await Process.run(bins.ffmpegPath, args);
    if (res.exitCode != 0) {
      final stderr = (res.stderr ?? '').toString();
      final stdout = (res.stdout ?? '').toString();
      throw Exception(
        'ffmpeg remux failed (code ${res.exitCode})\n'
        'stdout: $stdout\n'
        'stderr: $stderr',
      );
    }

    final out = File(outPath);
    if (!await out.exists()) {
      throw Exception('ffmpeg remux did not produce output file');
    }
    return out;
  }
}

