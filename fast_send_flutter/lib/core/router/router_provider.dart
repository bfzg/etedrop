import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../features/cloud/pages/cloud_page.dart';
import '../../features/message/pages/message_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/deskflow/pages/deskflow_page.dart';

class Routes {
  static const cloud = '/cloud';
  static const messages = '/messages';
  static const settings = '/settings';
  static const deskflow = '/deskflow';
}

List<NavItemConfig> buildNavItems(AppLocalizations l10n) => [
  NavItemConfig(
    label: '跨屏协同',
    outlinedIcon: Icons.devices_other_outlined,
    roundedIcon: Icons.devices_other,
    path: Routes.deskflow,
  ),
  NavItemConfig(
    label: l10n.messages,
    outlinedIcon: Icons.chat_bubble_outline,
    roundedIcon: Icons.chat_bubble,
    path: Routes.messages,
  ),
  NavItemConfig(
    label: l10n.cloud,
    outlinedIcon: Icons.cloud_outlined,
    roundedIcon: Icons.cloud_rounded,
    path: Routes.cloud,
  ),
  NavItemConfig(
    label: l10n.settings,
    outlinedIcon: Icons.settings_outlined,
    roundedIcon: Icons.settings_rounded,
    path: Routes.settings,
  ),
];

// 定义全局 navigatorKey
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.messages,
  routes: [
    // 底部导航页面
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        final l10n = AppLocalizations.of(context)!;
        return AppLayout(
          navigationShell: navigationShell,
          items: buildNavItems(l10n),
        );
      },
      branches: [
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
              path: Routes.cloud,
              builder: (context, state) => const CloudPage(),
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.deskflow,
              builder: (context, state) => const DeskflowPage(),
            ),
          ],
        ),
      ],
    ),

    // 非底部导航页面
    // GoRoute(path: Routes.login, builder: (context, state) => const LoginPage()),
  ],
);
