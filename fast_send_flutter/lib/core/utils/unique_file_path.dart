import 'dart:io';

import 'package:path/path.dart' as p;

/// 在 [directory] 下为 [fileName] 生成不冲突的保存路径（不覆盖已存在文件）。
/// 命名：`name (1).ext`, `name (2).ext`, …
Future<String> uniquePathInDirectory(String directory, String fileName) async {
  final base = p.basename(fileName);
  if (base.isEmpty) {
    return p.join(directory, 'file');
  }
  var candidate = p.join(directory, base);
  if (!await File(candidate).exists()) {
    return candidate;
  }
  final stem = p.basenameWithoutExtension(base);
  final ext = p.extension(base);
  var n = 1;
  while (n < 10000) {
    candidate = p.join(directory, '$stem ($n)$ext');
    if (!await File(candidate).exists()) {
      return candidate;
    }
    n++;
  }
  return p.join(
    directory,
    '$stem-${DateTime.now().millisecondsSinceEpoch}$ext',
  );
}
