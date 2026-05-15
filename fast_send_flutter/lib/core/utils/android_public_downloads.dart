import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

const _androidPublicDownloadsChannel = MethodChannel(
  'com.etedrop.app/public_downloads',
);

bool get _isAndroid => Platform.isAndroid;

String? _guessMimeTypeFromName(String fileName) {
  switch (p.extension(fileName).toLowerCase()) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.bmp':
      return 'image/bmp';
    case '.heic':
      return 'image/heic';
    case '.mp4':
      return 'video/mp4';
    case '.mov':
      return 'video/quicktime';
    case '.m4v':
      return 'video/x-m4v';
    case '.mkv':
      return 'video/x-matroska';
    case '.webm':
      return 'video/webm';
    case '.avi':
      return 'video/x-msvideo';
    case '.3gp':
      return 'video/3gpp';
    case '.mp3':
      return 'audio/mpeg';
    case '.m4a':
      return 'audio/mp4';
    case '.wav':
      return 'audio/wav';
    case '.pdf':
      return 'application/pdf';
    case '.txt':
      return 'text/plain';
    case '.json':
      return 'application/json';
    default:
      return null;
  }
}

Future<String?> copyFileToAndroidPublicDownloads(
  String sourcePath, {
  String? fileName,
}) async {
  if (!_isAndroid) return sourcePath;
  final source = File(sourcePath);
  if (!await source.exists()) return null;

  final resolvedName = (fileName == null || fileName.trim().isEmpty)
      ? p.basename(sourcePath)
      : fileName.trim();

  final result = await _androidPublicDownloadsChannel
      .invokeMethod<dynamic>('copyToPublicDownloads', <String, dynamic>{
        'sourcePath': source.absolute.path,
        'fileName': resolvedName,
        'mimeType': _guessMimeTypeFromName(resolvedName),
        'subdirectory': 'EteDrop',
      });

  if (result is Map) {
    final path = result['absolutePath'];
    if (path is String && path.isNotEmpty) {
      return path;
    }
  }
  return null;
}
