import 'package:flutter/material.dart';
import 'package:etedrop/core/utils/is_utils.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:go_router/go_router.dart';

import '../features/message/widgets/incoming_transfer_toast.dart';
import 'bottom_nav_bar.dart';
import 'sidebar_nav_bar.dart';

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
    // 用 MediaQuery 宽度代替 LayoutBuilder，避免热重载（reassemble）时
    // _LayoutBuilderElement.markNeedsBuild 与布局断言冲突（Flutter 已知类问题）。
    final useDesktopChrome =
        isDesktopPlatform() || MediaQuery.sizeOf(context).width >= 640;

    if (useDesktopChrome) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding:
              isWindowsPlatform() ? const EdgeInsets.all(4) : EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: isWindowsPlatform()
                  ? Radius.circular(14)
                  : Radius.circular(0),
              bottom: isWindowsPlatform()
                  ? Radius.circular(10)
                  : Radius.circular(0),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isWindowsPlatform()
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Colors.transparent,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSidebarNavBar(
                        items: widget.items,
                        currentIndex: widget.navigationShell.currentIndex,
                        onSelect: (index) => _onTap(context, index),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.horizontal(
                            left: isWindowsPlatform()
                                ? Radius.circular(0)
                                : Radius.circular(14),
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
                  const Positioned(
                    right: 16,
                    bottom: 16,
                    child: SafeArea(
                      child: IncomingTransferToast(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 窄屏模式（手机）使用底部导航栏
    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          const Positioned(
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: IncomingTransferToast(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        items: widget.items,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
