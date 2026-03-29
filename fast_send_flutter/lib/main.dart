import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app.dart';
import 'features/cloud/services/macos_cloud_storage_access.dart';
import 'services/desktop_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 窗口毛玻璃效果
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    await Window.initialize();
  }
  // 初始化本地存储
  await LocalStorageService.instance.init();
  // macOS 沙盒：恢复网盘目录安全作用域书签（须在访问用户所选路径前执行）
  await MacosCloudStorageAccess.restoreIfNeeded();
  // 初始化本地通知服务
  await NotificationService.instance.init();
  // 初始化桌面端服务 (托盘、窗口管理、开机自启)
  await DesktopService.instance.init();

  runApp(
    // Riverpod 必须用 ProviderScope 包裹
    const ProviderScope(child: App()),
  );
}
