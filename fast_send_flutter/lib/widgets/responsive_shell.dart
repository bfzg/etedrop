import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import 'bottom_nav_bar.dart';

const double _kSidebarWidth = 78;

// macOS 浅色侧边栏颜色（参考 macOS Sequoia sidebar）
const _kSidebarLightBg = Color(0xFFECECEC);
const _kSidebarDarkBg = Color(0xFF1E1E1E);

final bool _isDesktopPlatform =
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

class ResponsiveShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<NavItemConfig> items;

  const ResponsiveShell({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isDesktopPlatform || constraints.maxWidth >= 640) {
          return Scaffold(
            body: Column(
              children: [
                const _DraggableTopBar(),
                Expanded(
                  child: Row(
                    children: [
                      _Sidebar(
                        items: items,
                        currentIndex: navigationShell.currentIndex,
                        onSelect: (index) => _onTap(context, index),
                      ),
                      Expanded(child: navigationShell),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // 窄屏模式（手机）使用底部导航栏
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: navigationShell.currentIndex,
            items: items,
            onTap: (index) => _onTap(context, index),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// 仅顶部可拖动区域（含侧边栏上方一条），用于移动窗口；内容区不可拖动，侧边栏 item 双击不会触发全屏。
class _DraggableTopBar extends StatelessWidget {
  const _DraggableTopBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.paddingOf(context).top;
    final isMacOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final height = isMacOS ? topInset + 34 : 32.0;
    final sidebarBg = isDark ? _kSidebarDarkBg : _kSidebarLightBg;

    return DragToMoveArea(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            ColoredBox(
              color: sidebarBg,
              child: SizedBox(width: _kSidebarWidth, height: height),
            ),
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<NavItemConfig> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _Sidebar({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? _kSidebarDarkBg : _kSidebarLightBg;

    return SizedBox(
      width: _kSidebarWidth,
      child: ColoredBox(
        color: sidebarBg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 侧边栏空白区域可拖拽移动窗口；导航按钮位于上层保持可点击。
            const DragToMoveArea(child: SizedBox.expand()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 顶部留白已由 _DraggableTopBar 占据，侧边栏仅保留导航项，避免 item 处于可拖动区导致双击全屏
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: _SidebarItem(
                            item: item,
                            selected: index == currentIndex,
                            isDark: isDark,
                            onTap: () => onSelect(index),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final NavItemConfig item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    final normalColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF1C1C1E).withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(
                selected ? item.roundedIcon : item.outlinedIcon,
                size: 20,
                color: selected ? selectedColor : normalColor,
              ),
              const SizedBox(width: 9),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected ? selectedColor : normalColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
