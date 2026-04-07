import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../services/desktop_service.dart';

part 'settings_provider.g.dart';

/// 执行桌面端异步设置；勿用 autoDispose，否则 await 间隙 Ref 会被回收，invalidate 抛错且开关不刷新。
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  FutureOr<void> build() {}

  // 切换开机自启
  Future<void> toggleAutoStart(bool enable) async {
    await DesktopService.instance.toggleAutoStart(enable);
    if (ref.mounted) {
      ref.invalidate(autoStartEnabledProvider);
    }
  }

  // 切换最小化到托盘
  Future<void> toggleMinimizeToTray(bool enable) async {
    // 这里我们直接复用 window_manager 的 preventClose 状态
    // 如果 preventClose 为 true，则点击关闭时会隐藏窗口（即最小化到托盘）
    // 如果 preventClose 为 false，则点击关闭时会销毁窗口（退出应用）
    if (enable) {
      await DesktopService.instance.setPreventClose(true);
    } else {
      await DesktopService.instance.setPreventClose(false);
    }
    if (ref.mounted) {
      ref.invalidate(minimizeToTrayEnabledProvider);
    }
  }
}

@riverpod
Future<bool> autoStartEnabled(Ref ref) async {
  return await DesktopService.instance.isAutoStartEnabled;
}

@riverpod
Future<bool> minimizeToTrayEnabled(Ref ref) async {
  return await DesktopService.instance.isPreventClose;
}
