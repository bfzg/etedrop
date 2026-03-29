import 'dart:io';

import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';

import '../../../services/local_storage_service.dart';
import '../cloud_storage_prefs.dart';

final _secureBookmarks = SecureBookmarks();

/// macOS 沙盒下用户通过面板选择的目录需用安全作用域书签才能在进程重启后访问。
class MacosCloudStorageAccess {
  MacosCloudStorageAccess._();

  /// 非 null 表示已在 [main] 中通过书签恢复并开始访问，应与持久化路径一致。
  static String? scopedStorageDir;

  static Future<void> restoreIfNeeded() async {
    scopedStorageDir = null;
    if (!Platform.isMacOS) return;

    final prefs = LocalStorageService.instance;
    final userSelected =
        prefs.get<bool>(kCloudStorageDirUserSelectedKey) ?? false;
    if (!userSelected) return;

    final bookmark = prefs.get<String>(kCloudStorageDirBookmarkKey);
    if (bookmark == null || bookmark.isEmpty) return;

    try {
      final entity =
          await _secureBookmarks.resolveBookmark(bookmark, isDirectory: true);
      final started =
          await _secureBookmarks.startAccessingSecurityScopedResource(entity);
      if (started) {
        scopedStorageDir = entity.absolute.path;
        final saved = prefs.get<String>(kCloudStorageDirKey);
        if (saved != scopedStorageDir) {
          await prefs.set<String>(kCloudStorageDirKey, scopedStorageDir!);
        }
      }
    } catch (_) {
      // 书签失效或用户撤销授权
    }
  }

  static Future<void> persistBookmarkForPath(String path) async {
    if (!Platform.isMacOS) return;
    try {
      final data = await _secureBookmarks.bookmark(Directory(path));
      await LocalStorageService.instance
          .set<String>(kCloudStorageDirBookmarkKey, data);
    } catch (_) {
      // 尽力持久化；失败时下次启动可能需重新选择目录
    }
  }
}
