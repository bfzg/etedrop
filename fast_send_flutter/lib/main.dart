import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app.dart';
import 'services/desktop_service.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化本地存储
  await LocalStorageService.instance.init();
  // 初始化桌面端服务 (托盘、窗口管理、开机自启)
  await DesktopService.instance.init();
  
  runApp(
    // Riverpod 必须用 ProviderScope 包裹
    const ProviderScope(child: App()),
  );
}
