import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

/// 在系统文件管理器中显示 [absoluteFilePath]（尽量选中该文件）。
///
/// - 桌面：macOS / Windows / Linux 按「在文件夹中显示」语义处理。
/// - Android / iOS：应用沙盒或 `Android/data` 下路径无法被系统「文件」应用当作文件夹打开，
///   因此改为用系统已安装应用打开该文件（图片/视频/文档等），便于用户查看已接收内容。
Future<bool> revealFileInExplorer(String absoluteFilePath) async {
  final normalized = p.normalize(absoluteFilePath);
  final file = File(normalized);
  if (!await file.exists()) return false;

  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final r = await OpenFilex.open(file.absolute.path);
      return r.type == ResultType.done;
    }
    if (Platform.isMacOS) {
      final r = await Process.run('open', ['-R', file.absolute.path]);
      return r.exitCode == 0;
    }
    if (Platform.isWindows) {
      // explorer.exe 常在已成功打开并选中文件时仍返回非零退出码，不能据此判断失败。
      // Windows 的 explorer /select 参数对引号和分隔符很敏感。
      // 通过 cmd/start 让 Windows 自己解析完整命令行，并强制反斜杠路径；
      // 否则包含空格、中文或正斜杠的路径在部分环境会退回到默认文档目录。
      final target = await _windowsExplorerPath(file);
      final selectArg = '/select,"$target"';
      await Process.run('cmd.exe', [
        '/c',
        'start',
        '',
        'explorer.exe',
        selectArg,
      ]);
      return true;
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

Future<String> _windowsExplorerPath(File file) async {
  try {
    return (await file.resolveSymbolicLinks()).replaceAll('/', r'\');
  } catch (_) {
    return file.absolute.path.replaceAll('/', r'\');
  }
}
