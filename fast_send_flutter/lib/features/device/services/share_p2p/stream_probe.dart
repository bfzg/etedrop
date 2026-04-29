import 'dart:io';

import 'package:path/path.dart' as p;

import '../video_stream_plan.dart';

Future<double?> probeShareMediaDuration(
  String ffprobePath,
  String inputPath,
) async {
  try {
    final res = await Process.run(ffprobePath, [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'default=nw=1:nk=1',
      inputPath,
    ]);
    if (res.exitCode != 0) return null;
    final out = (res.stdout ?? '').toString().trim();
    if (out.isEmpty || out == 'N/A') return null;
    return double.tryParse(out.split(RegExp(r'\r?\n')).first.trim());
  } catch (_) {
    return null;
  }
}

Future<String?> probeShareStreamCodec(
  String ffprobePath,
  String inputPath, {
  required String streamSelector,
}) async {
  try {
    final res = await Process.run(ffprobePath, [
      '-v',
      'error',
      '-select_streams',
      streamSelector,
      '-show_entries',
      'stream=codec_name',
      '-of',
      'default=nw=1:nk=1',
      inputPath,
    ]);
    if (res.exitCode != 0) return null;
    final out = (res.stdout ?? '').toString().trim();
    if (out.isEmpty) return null;
    return out.split(RegExp(r'\r?\n')).first.trim();
  } catch (_) {
    return null;
  }
}

Future<({int width, int height})?> probeShareVideoSize(
  String ffprobePath,
  String inputPath,
) async {
  try {
    final res = await Process.run(ffprobePath, [
      '-v',
      'error',
      '-select_streams',
      'v:0',
      '-show_entries',
      'stream=width,height',
      '-of',
      'csv=p=0:s=x',
      inputPath,
    ]);
    if (res.exitCode != 0) return null;
    final out = (res.stdout ?? '').toString().trim();
    if (out.isEmpty) return null;
    final line = out.split(RegExp(r'\r?\n')).first.trim();
    final parts = line.split('x');
    if (parts.length != 2) return null;
    final w = int.tryParse(parts[0]);
    final h = int.tryParse(parts[1]);
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return (width: w, height: h);
  } catch (_) {
    return null;
  }
}

/// 一次性 ffprobe，供 [VideoStreamPlanner.plan] 使用。
Future<VideoStreamProbe> probeShareVideoStream(
  String ffprobePath,
  String inputPath,
) async {
  final results = await Future.wait<Object?>([
    probeShareStreamCodec(ffprobePath, inputPath, streamSelector: 'v:0'),
    probeShareStreamCodec(ffprobePath, inputPath, streamSelector: 'a:0'),
    probeShareMediaDuration(ffprobePath, inputPath),
    probeShareVideoSize(ffprobePath, inputPath),
  ]);
  final size = results[3] as ({int width, int height})?;
  return VideoStreamProbe(
    videoCodec: results[0] as String?,
    audioCodec: results[1] as String?,
    width: size?.width,
    height: size?.height,
    duration: results[2] as double?,
    fileExtensionLower: p
        .extension(inputPath)
        .toLowerCase()
        .replaceFirst('.', ''),
  );
}
