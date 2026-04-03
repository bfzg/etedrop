import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/transfer_message.dart';

String? trimCaption(TransferMessage m) {
  final s = m.caption?.trim();
  if (s == null || s.isEmpty) return null;
  return s;
}

bool isLikelyImageFileName(String name) {
  switch (p.extension(name).toLowerCase()) {
    case '.png':
    case '.jpg':
    case '.jpeg':
    case '.gif':
    case '.webp':
    case '.bmp':
    case '.heic':
      return true;
    default:
      return false;
  }
}

/// 可在卡片内直接展示正文的纯文本类附件（与 [fileTypePngForFileName] 中文本类一致）。
bool isPlainTextPreviewFileName(String name) {
  switch (p.extension(name).toLowerCase()) {
    case '.txt':
    case '.md':
    case '.log':
    case '.json':
    case '.xml':
    case '.yaml':
    case '.yml':
    case '.toml':
    case '.csv':
      return true;
    default:
      return false;
  }
}

List<String>? decodedLocalPaths(TransferMessage m) {
  final raw = m.localFilePathsJson;
  if (raw == null || raw.isEmpty) return null;
  try {
    return List<String>.from(jsonDecode(raw) as List);
  } catch (_) {
    return null;
  }
}

String? pathAt(List<String>? list, int index) {
  if (list == null || index < 0 || index >= list.length) return null;
  final s = list[index];
  if (s.isEmpty) return null;
  if (File(s).existsSync()) return s;
  return null;
}

List<Map<String, dynamic>>? decodeBatchFiles(TransferMessage m) {
  if (!m.isBatch || m.batchFilesJson == null) return null;
  try {
    final list = jsonDecode(m.batchFilesJson!) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return null;
  }
}
