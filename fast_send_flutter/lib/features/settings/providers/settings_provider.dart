import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../services/desktop_service.dart';

part 'settings_provider.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  FutureOr<void> build() {}

  // 切换开机自启
  Future<void> toggleAutoStart(bool enable) async {
    await DesktopService.instance.toggleAutoStart(enable);
    ref.invalidate(autoStartEnabledProvider);
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
    ref.invalidate(minimizeToTrayEnabledProvider);
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
