import 'package:flutter/foundation.dart';

/// 判断是否为桌面平台
bool isDesktopPlatform() {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
       defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.linux);
}


/// 判断是否为 macOS 平台
bool isMacOSPlatform() {
  return defaultTargetPlatform == TargetPlatform.macOS;
}

/// 判断是否为 Windows 平台
bool isWindowsPlatform() {
  return defaultTargetPlatform == TargetPlatform.windows;
}

/// 判断是否为 Linux 平台
bool isLinuxPlatform() {
  return defaultTargetPlatform == TargetPlatform.linux;
}