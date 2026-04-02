import 'package:eddy/core/utils/is_utils.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'bottom_nav_bar.dart';
import '../core/config/styles.dart';
import '../features/message/providers/message_provider.dart';

const double kSidebarWidth = 68;

/// 桌面端侧边栏导航（支持 DragToMoveArea 拖动窗口）。
class AppSidebarNavBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingMessageCountProvider);
    // macOS 下预留顶部安全距离，避免导航项与红黄绿按钮重叠（预留高度略收窄）
    final topInset = isMacOSPlatform() ? 38.0 : 10.0;
    final padding = EdgeInsets.fromLTRB(5.0, 5.0 + topInset, 5.0, 0.0);

    return SizedBox(
      width: kSidebarWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: isWindowsPlatform()
              ? Border(
                  right: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.10),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
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
                        final badge =
                            (item.path == '/messages' && pendingCount > 0)
                            ? pendingCount
                            : 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SidebarItem(
                            item: item,
                            selected: index == currentIndex,
                            badgeCount: badge,
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
  final int badgeCount;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppStyles.primary;

    final normalColor = const Color(0xFF000000).withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.black.withValues(alpha: 0.04),
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
              Badge(
                isLabelVisible: badgeCount > 0,
                label: Text(
                  '$badgeCount',
                  style: const TextStyle(fontSize: 10),
                ),
                child: Icon(
                  selected ? item.roundedIcon : item.outlinedIcon,
                  size: 20,
                  color: selected ? selectedColor : normalColor,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: selected ? selectedColor : normalColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
