import 'dart:io';

import 'package:path/path.dart' as p;

/// 在系统文件管理器中显示 [absoluteFilePath]（尽量选中该文件）。
/// 桌面端支持 macOS / Windows / Linux；移动端返回 false。
Future<bool> revealFileInExplorer(String absoluteFilePath) async {
  final normalized = p.normalize(absoluteFilePath);
  final file = File(normalized);
  if (!await file.exists()) return false;

  try {
    if (Platform.isMacOS) {
      final r = await Process.run('open', ['-R', file.absolute.path]);
      return r.exitCode == 0;
    }
    if (Platform.isWindows) {
      final r = await Process.run('explorer', ['/select,', file.absolute.path]);
      return r.exitCode == 0;
    }
    if (Platform.isLinux) {
      final dir = p.dirname(file.absolute.path);
      final r = await Process.run('xdg-open', [dir]);
      return r.exitCode == 0;
    }
  } catch (_) {
    return false;
  }
  return false;
}
