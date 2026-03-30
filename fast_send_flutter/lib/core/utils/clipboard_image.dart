import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';

/// 从系统剪贴板读取图片（macOS / Windows / Linux 等为原生实现）。
Future<Uint8List?> readClipboardImageBytes() async {
  try {
    final bytes = await Pasteboard.image;
    if (bytes == null || bytes.isEmpty) return null;
    return bytes;
  } catch (_) {
    return null;
  }
}

Future<Directory> _appWritableSubdirectory(String segment) async {
  Directory base;
  try {
    base = await getApplicationCacheDirectory();
  } catch (_) {
    base = Directory.systemTemp;
  }
  final sub = Directory(p.join(base.path, segment));
  await sub.create(recursive: true);
  return sub;
}

/// 将剪贴板图片写入应用 Caches 子目录，返回绝对路径（避免沙盒下 [getTemporaryDirectory] 非绝对路径导致写入失败）。
Future<String> saveClipboardImageBytesToTempFile(Uint8List bytes) async {
  final sub = await _appWritableSubdirectory('clipboard_paste');
  final name = 'paste_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File(p.join(sub.path, name));
  await file.writeAsBytes(bytes, flush: true);
  return file.absolute.path;
}

/// 纯文字发送时写入临时 .txt，同样使用 Caches 子目录。
Future<String> saveOutgoingTextMessageToTempFile(String utf8Content) async {
  final sub = await _appWritableSubdirectory('outgoing_text');
  final name = '文字消息_${DateTime.now().millisecondsSinceEpoch}.txt';
  final file = File(p.join(sub.path, name));
  await file.writeAsString(utf8Content, flush: true);
  return file.absolute.path;
}
