// 负责初始化窗口管理、系统托盘、开机自启等桌面端相关功能

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/config/constants.dart';
import '../l10n/app_localizations.dart';

class DesktopService with TrayListener, WindowListener {
  static final DesktopService instance = DesktopService._internal();
  DesktopService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (!isDesktop || _isInitialized) return;

    // 1. 初始化窗口管理
    await windowManager.ensureInitialized();
    final titleBarStyle = Platform.isMacOS
        ? TitleBarStyle.hidden
        : TitleBarStyle.normal;
    WindowOptions windowOptions = WindowOptions(
      size: const Size(1024, 768),
      minimumSize: const Size(900, 600),
      center: true,
      skipTaskbar: false,
      titleBarStyle: titleBarStyle,
    );

    windowManager.addListener(this);

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // 2. 初始化开机自启
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    LaunchAtStartup.instance.setup(
      appName: AppConstants.appName,
      appPath: Platform.resolvedExecutable,
      packageName: packageInfo.packageName,
    );

    // 3. 初始化系统托盘
    await _initSystemTray();

    // 4. 设置窗口关闭行为（最小化到托盘）
    await windowManager.setPreventClose(true);

    _isInitialized = true;
  }

  Future<void> _initSystemTray() async {
    // Windows：托盘区用专用 PNG；macOS：菜单栏 PNG + isTemplate。
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/images/windows_icon_stat_bar.png'
          : Platform.isMacOS
              ? 'assets/images/mac_icon_state_bar.png'
              : 'assets/images/app_icon.png',
      isTemplate: Platform.isMacOS,
    );

    if (!Platform.isLinux) {
      await trayManager.setToolTip(AppConstants.appName);
    }

    await updateTrayMenu(
      lookupAppLocalizations(const Locale('en')),
    );
    trayManager.addListener(this);
  }

  Future<void> updateTrayMenu(AppLocalizations l10n) async {
    if (!isDesktop) return;
    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: l10n.trayOpenApp(AppConstants.appName),
        ),
        MenuItem.separator(),
        MenuItem(key: 'quit_app', label: l10n.trayQuit),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      showWindow();
    } else if (menuItem.key == 'quit_app') {
      quitApp();
    }
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hideWindow() async {
    await windowManager.hide();
  }

  Future<void> quitApp() async {
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  Future<bool> get isAutoStartEnabled => LaunchAtStartup.instance.isEnabled();

  Future<void> toggleAutoStart(bool enable) async {
    if (enable) {
      await LaunchAtStartup.instance.enable();
    } else {
      await LaunchAtStartup.instance.disable();
    }
  }

  Future<void> setPreventClose(bool prevent) async {
    await windowManager.setPreventClose(prevent);
  }

  Future<bool> get isPreventClose async {
    return await windowManager.isPreventClose();
  }

  bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}
