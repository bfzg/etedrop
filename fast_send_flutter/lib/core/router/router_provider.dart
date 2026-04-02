import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_layout.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../features/cloud/pages/cloud_page.dart';
import '../../features/transfer/pages/send_page.dart';
import '../../features/message/pages/message_page.dart';
import '../../features/settings/pages/settings_page.dart';

class Routes {
  static const cloud = '/cloud';
  static const send = '/send';
  static const messages = '/messages';
  static const settings = '/settings';
}

// 导航项配置列表
final List<NavItemConfig> navItems = [
  NavItemConfig(
    label: '网盘',
    outlinedIcon: Icons.cloud_outlined,
    roundedIcon: Icons.cloud_rounded,
    path: Routes.cloud,
  ),
  NavItemConfig(
    label: '附近',
    outlinedIcon: Icons.wifi_tethering,
    roundedIcon: Icons.wifi_tethering,
    path: Routes.send,
  ),
  NavItemConfig(
    label: '消息',
    outlinedIcon: Icons.chat_bubble_outline,
    roundedIcon: Icons.chat_bubble,
    path: Routes.messages,
  ),
  NavItemConfig(
    label: '设置',
    outlinedIcon: Icons.settings_outlined,
    roundedIcon: Icons.settings_rounded,
    path: Routes.settings,
  ),
];

// 定义全局 navigatorKey
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.cloud,
  routes: [
    // 底部导航页面
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppLayout(navigationShell: navigationShell, items: navItems);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.cloud,
              builder: (context, state) => const CloudPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.send,
              builder: (context, state) => const SendPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.messages,
              builder: (context, state) => const MessagePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),

    // 非底部导航页面
    // GoRoute(path: Routes.login, builder: (context, state) => const LoginPage()),
  ],
);
