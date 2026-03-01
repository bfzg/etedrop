import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../cloud/providers/cloud_provider.dart';
import '../../device/providers/device_provider.dart';
import '../providers/settings_provider.dart';
import '../../../services/desktop_service.dart';

import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';

/// 设置页面
/// 对应 Electron: src/routes/settings.tsx → SettingsPage
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final storagePath = ref.watch(storageDirPathProvider);
    final connected = ref.watch(deviceConnectedProvider);
    final devName = ref.watch(deviceNameProvider);
    final devId = ref.watch(deviceIdProvider);

    // 桌面端设置状态
    final isDesktop = DesktopService.instance.isDesktop;
    final autoStart = ref.watch(autoStartEnabledProvider).value ?? false;
    final minimizeToTray =
        ref.watch(minimizeToTrayEnabledProvider).value ?? false;

    // 主题和语言状态
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      appBar: isDesktopLayout ? null : AppBar(title: Text(l10n.settings)),
      body: Center(
        child: ListView(
          children: [
            // ---- 设备信息 ----
            _SectionHeader(title: l10n.deviceInfo),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      connected ? Icons.cloud_done : Icons.cloud_off,
                      color: connected
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(devName),
                    subtitle: Text(
                      connected ? l10n.connected : l10n.disconnected,
                    ),
                    trailing: connected
                        ? null
                        : FilledButton.tonal(
                            onPressed: () => ref
                                .read(deviceManagerProvider.notifier)
                                .connectToServer(),
                            child: Text(l10n.connect),
                          ),
                  ),
                  const Divider(height: 1, indent: 56),
                  if (devId != null) ...[
                    ListTile(
                      leading: const Icon(Icons.fingerprint),
                      title: Text(l10n.deviceId),
                      subtitle: Text(
                        devId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                  ],
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(l10n.editDeviceName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showRenameDialog(context, ref, devName, l10n),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---- 存储 ----
            _SectionHeader(title: l10n.storage),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.folder),
                title: Text(l10n.storagePath),
                subtitle: Text(storagePath.isEmpty ? l10n.notSet : storagePath),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    ref.read(fileServiceProvider.notifier).selectStorageDir(),
              ),
            ),

            const SizedBox(height: 16),

            // ---- 桌面端设置 ----
            if (isDesktop) ...[
              _SectionHeader(title: l10n.desktopIntegration),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.power_settings_new),
                      title: Text(l10n.launchAtStartup),
                      value: autoStart,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .toggleAutoStart(value),
                    ),
                    const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      secondary: const Icon(Icons.close),
                      title: Text(l10n.minimizeToTray),
                      subtitle: Text(l10n.minimizeToTrayDesc),
                      value: minimizeToTray,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .toggleMinimizeToTray(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ---- 外观 ----
            _SectionHeader(title: l10n.appearance),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: Text(l10n.darkMode),
                    subtitle: Text(_getThemeModeText(themeMode, l10n)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _showThemeDialog(context, ref, themeMode, l10n),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.language),
                    subtitle: Text(
                      locale?.languageCode == 'zh'
                          ? '简体中文'
                          : (locale?.languageCode == 'en'
                                ? 'English'
                                : l10n.followSystem),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _showLanguageDialog(context, ref, locale, l10n),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---- 关于 ----
            _SectionHeader(title: l10n.about),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('FastSend'),
                subtitle: Text('v1.0.0'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editDeviceName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.inputDeviceName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && result != currentName) {
      await ref.read(deviceManagerProvider.notifier).setDeviceName(result);
    }
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
    AppLocalizations l10n,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.selectTheme),
          children: [
            _buildSelectionOption(
              context,
              title: l10n.followSystem,
              selected: currentMode == ThemeMode.system,
              onTap: () {
                ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
                Navigator.of(context).pop();
              },
            ),
            _buildSelectionOption(
              context,
              title: l10n.lightMode,
              selected: currentMode == ThemeMode.light,
              onTap: () {
                ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
                Navigator.of(context).pop();
              },
            ),
            _buildSelectionOption(
              context,
              title: l10n.darkMode,
              selected: currentMode == ThemeMode.dark,
              onTap: () {
                ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    Locale? currentLocale,
    AppLocalizations l10n,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.language),
          children: [
            _buildSelectionOption(
              context,
              title: l10n.followSystem,
              selected: currentLocale == null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(null);
                Navigator.of(context).pop();
              },
            ),
            _buildSelectionOption(
              context,
              title: '简体中文',
              selected: currentLocale?.languageCode == 'zh',
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('zh'));
                Navigator.of(context).pop();
              },
            ),
            _buildSelectionOption(
              context,
              title: 'English',
              selected: currentLocale?.languageCode == 'en',
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectionOption(
    BuildContext context, {
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SimpleDialogOption(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: selected ? Theme.of(context).colorScheme.primary : null,
              fontWeight: selected ? FontWeight.bold : null,
            ),
          ),
          if (selected)
            Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.followSystem;
      case ThemeMode.light:
        return l10n.lightMode;
      case ThemeMode.dark:
        return l10n.darkMode;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
