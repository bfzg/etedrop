import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/is_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import 'bottom_nav_bar.dart';

const double _kSidebarWidth = 78;

// macOS 浅色侧边栏颜色（参考 macOS Sequoia sidebar）
const _kSidebarLightBg = Color(0xFFECECEC);
const _kSidebarDarkBg = Color(0xFF1E1E1E);

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
        if (isDesktopPlatform() || constraints.maxWidth >= 640) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  items: items,
                  currentIndex: navigationShell.currentIndex,
                  onSelect: (index) => _onTap(context, index),
                ),
                Expanded(child: navigationShell),
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

/// 桌面端通过侧边栏的 DragToMoveArea 拖动窗口；无单独顶部栏，避免与页面 AppBar 叠成双栏。
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
    // macOS 下预留顶部安全距离，避免导航项与红黄绿按钮重叠
    final topInset = isMacOSPlatform() ? 20.0 : 0.0;
    final padding = EdgeInsets.fromLTRB(8.0, 8.0 + topInset, 8.0, 0.0);

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
                // 侧边栏空白区域可拖动移动窗口，导航项在上层保持可点击
                Expanded(
                  child: Padding(
                    padding: padding,
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
              const SizedBox(height: 4),
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
