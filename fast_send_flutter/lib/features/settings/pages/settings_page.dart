import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../cloud/providers/cloud_provider.dart';
import '../../device/providers/device_provider.dart';
import '../providers/settings_provider.dart';
import '../../../services/desktop_service.dart';
import '../providers/locale_provider.dart';
import '../widgets/about_section.dart';
import '../widgets/appearance_section.dart';
import '../widgets/desktop_integration_section.dart';
import '../widgets/device_info_section.dart';
import '../widgets/network_line_section.dart';
import '../widgets/storage_section.dart';
import '../widgets/transfer_receive_section.dart';
import '../widgets/webrtc_background_section.dart';

/// 设置页面
/// 对应 Electron: src/routes/settings.tsx → SettingsPage
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 进入设置页即加载设备配置，保证名称/头像显示和修改立即生效
    ref.watch(deviceConfigReadyProvider);

    final storagePath = ref.watch(storageDirPathProvider);
    final downloadPath = ref.watch(downloadDirProvider).value ?? '';
    final connected = ref.watch(deviceConnectedProvider);
    final connecting = ref.watch(deviceConnectingProvider);
    final lastError = ref.watch(deviceLastConnectionErrorProvider);
    final devName = ref.watch(deviceNameProvider);
    final devId = ref.watch(deviceIdProvider);

    // 桌面端设置状态
    final isDesktop = DesktopService.instance.isDesktop;
    final autoStart = ref.watch(autoStartEnabledProvider).value ?? false;
    final minimizeToTray =
        ref.watch(minimizeToTrayEnabledProvider).value ?? false;

    // 语言状态
    final locale = ref.watch(localeProvider);

    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      appBar: null,
      body: SafeArea(
        top: !isDesktopLayout,
        bottom: false,
        child: Center(
          child: ListView(
            children: [
            DeviceInfoSection(
              connected: connected,
              connecting: connecting,
              lastError: lastError,
              devName: devName,
              devId: devId,
            ),

            const SizedBox(height: 16),

            StorageSection(
              storagePath: storagePath,
              downloadPath: downloadPath,
            ),

            const SizedBox(height: 16),

            const TransferReceiveSection(),

            const SizedBox(height: 16),

            const WebrtcBackgroundSection(),

            const SizedBox(height: 16),

            if (isDesktop) ...[
              DesktopIntegrationSection(
                autoStart: autoStart,
                minimizeToTray: minimizeToTray,
              ),
              const SizedBox(height: 16),
            ],

            AppearanceSection(locale: locale),

            const SizedBox(height: 16),
            const NetworkLineSection(),
            const SizedBox(height: 16),
            const AboutSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }
}
