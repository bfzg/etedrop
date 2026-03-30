import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 剪贴板粘贴图片写入的子目录名（位于应用 Caches 下）。
const kTransferClipboardPasteDir = 'clipboard_paste';

/// 纯文字临时 .txt 写入的子目录名。
const kTransferOutgoingTextDir = 'outgoing_text';

Future<Directory> _applicationCacheOrSystemTemp() async {
  try {
    return await getApplicationCacheDirectory();
  } catch (_) {
    return Directory.systemTemp;
  }
}

/// 确保子目录存在（用于写入临时文件）。
Future<Directory> ensureTransferTempSubdirectory(String segment) async {
  final base = await _applicationCacheOrSystemTemp();
  final sub = Directory(p.join(base.path, segment));
  await sub.create(recursive: true);
  return sub;
}

bool _isUnderPrefix(String filePath, String dirPath) {
  final f = p.normalize(File(filePath).absolute.path);
  final d = p.normalize(dirPath);
  final prefix = d.endsWith(p.separator) ? d : '$d${p.separator}';
  return f == d || f.startsWith(prefix);
}

/// 是否为我们在 Caches 下管理的临时路径（仅 [kTransferClipboardPasteDir] / [kTransferOutgoingTextDir]）。
Future<bool> isManagedTransferTempPath(String absolutePath) async {
  final base = await _applicationCacheOrSystemTemp();
  final root = p.normalize(base.absolute.path);
  return _isUnderPrefix(
        absolutePath,
        p.join(root, kTransferClipboardPasteDir),
      ) ||
      _isUnderPrefix(absolutePath, p.join(root, kTransferOutgoingTextDir));
}

/// 删除由本模块写入的临时文件；非管理路径（用户自选文件等）会跳过。
Future<void> deleteManagedTransferTempPaths(Iterable<String> paths) async {
  for (final path in paths) {
    if (!await isManagedTransferTempPath(path)) continue;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}

/// 删除 [kTransferClipboardPasteDir]、[kTransferOutgoingTextDir] 内修改时间早于 [maxAge] 的文件。
Future<void> pruneTransferTempCacheOlderThan(Duration maxAge) async {
  final cutoff = DateTime.now().subtract(maxAge);
  final base = await _applicationCacheOrSystemTemp();
  for (final segment in [
    kTransferClipboardPasteDir,
    kTransferOutgoingTextDir,
  ]) {
    final dir = Directory(p.join(base.path, segment));
    if (!await dir.exists()) continue;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      try {
        if ((await entity.lastModified()).isBefore(cutoff)) {
          await entity.delete();
        }
      } catch (_) {}
    }
  }
}
