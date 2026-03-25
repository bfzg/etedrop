import 'package:flutter/material.dart';

import '../core/config/styles.dart';

// 导航项配置模型
class NavItemConfig {
  final String label;
  final IconData outlinedIcon;
  final IconData roundedIcon;
  final String path;

  const NavItemConfig({
    required this.label,
    required this.outlinedIcon,
    required this.roundedIcon,
    required this.path,
  });
}

// 封装的底部导航栏组件
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<NavItemConfig> items;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      // 通过主题覆盖移除水波纹效果
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        // 保持文字大小一致
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedItemColor: AppStyles.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = currentIndex == index;

          return BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              index: index,
              isSelected: isSelected,
              outlinedIcon: item.outlinedIcon,
              roundedIcon: item.roundedIcon,
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

// 带动画的导航图标组件
class AnimatedNavIcon extends StatelessWidget {
  final int index;
  final bool isSelected;
  final IconData outlinedIcon;
  final IconData roundedIcon;

  const AnimatedNavIcon({
    super.key,
    required this.index,
    required this.isSelected,
    required this.outlinedIcon,
    required this.roundedIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutBack,
      transform: Matrix4.identity()..scaleByDouble(1.0, 1.0, 1.0, 1.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          isSelected ? roundedIcon : outlinedIcon,
          key: ValueKey(isSelected),
          size: index == 0 ? 28 : 24,
        ),
      ),
    );
  }
}
