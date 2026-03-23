import 'package:flutter/material.dart';
import 'package:eddy/core/utils/is_utils.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import 'bottom_nav_bar.dart';

const double _kSidebarWidth = 68;

/// 应用主布局：桌面端侧栏 + 主内容（左侧圆角），窄屏底部导航。
class AppLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<NavItemConfig> items;

  const AppLayout({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  WindowEffect? _appliedEffect;
  Brightness? _appliedBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyWindowEffectIfNeeded();
  }

  Future<void> _applyWindowEffectIfNeeded() async {
    if (!isDesktopPlatform()) return;

    final brightness = Theme.of(context).brightness;
    final effect = _resolveWindowEffect();
    if (_appliedEffect == effect && _appliedBrightness == brightness) return;

    await Window.setEffect(effect: effect, dark: brightness == Brightness.dark);

    _appliedEffect = effect;
    _appliedBrightness = brightness;
  }

  WindowEffect _resolveWindowEffect() {
    if (isMacOSPlatform()) return WindowEffect.sidebar;
    if (isWindowsPlatform()) return WindowEffect.acrylic;
    return WindowEffect.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isDesktopPlatform() || constraints.maxWidth >= 640) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: [
                _AcrylicSidebar(
                  items: widget.items,
                  currentIndex: widget.navigationShell.currentIndex,
                  onSelect: (index) => _onTap(context, index),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: widget.navigationShell,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 窄屏模式（手机）使用底部导航栏
        return Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: widget.navigationShell.currentIndex,
            items: widget.items,
            onTap: (index) => _onTap(context, index),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

/// 桌面端通过侧边栏的 DragToMoveArea 拖动窗口；无单独顶部栏，避免与页面 AppBar 叠成双栏。
class _AcrylicSidebar extends StatelessWidget {
  final List<NavItemConfig> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _AcrylicSidebar({
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
      width: _kSidebarWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(),
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
