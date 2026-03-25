import 'package:eddy/core/utils/is_utils.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'bottom_nav_bar.dart';
import '../core/config/styles.dart';

const double kSidebarWidth = 68;

/// 桌面端侧边栏导航（支持 DragToMoveArea 拖动窗口）。
class AppSidebarNavBar extends StatelessWidget {
  final List<NavItemConfig> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const AppSidebarNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // macOS 下预留顶部安全距离，避免导航项与红黄绿按钮重叠（预留高度略收窄）
    final topInset = isMacOSPlatform() ? 38.0 : 10.0;
    final padding = EdgeInsets.fromLTRB(5.0, 5.0 + topInset, 5.0, 0.0);

    return SizedBox(
      width: kSidebarWidth,
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 侧边栏空白区域可拖拽移动窗口；导航按钮位于上层保持可点击。
            const DragToMoveArea(child: SizedBox.expand()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
    final selectedColor = isDark ? Colors.white : AppStyles.primary;

    final normalColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF000000).withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.roundedIcon : item.outlinedIcon,
                size: 20,
                color: selected ? selectedColor : normalColor,
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
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
