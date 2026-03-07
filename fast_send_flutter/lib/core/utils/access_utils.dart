import 'dart:io';

/// 在 macOS 上打开「系统设置 → 隐私与安全性 → 完全磁盘访问权限」页面，
/// 方便用户为本应用授权后重试。
Future<void> openMacOsFullDiskAccessSettings() async {
  if (!Platform.isMacOS) return;
  try {
    await Process.run('open', [
      'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles',
    ], runInShell: false);
  } catch (_) {}
}
