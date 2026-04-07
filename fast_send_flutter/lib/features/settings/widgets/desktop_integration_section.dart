import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class DesktopIntegrationSection extends ConsumerWidget {
  final bool autoStart;
  final bool minimizeToTray;

  const DesktopIntegrationSection({
    super.key,
    required this.autoStart,
    required this.minimizeToTray,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.desktopIntegration),
        SettingsCard(
          child: Column(
            children: [
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.power_settings_new),
                title: Text(l10n.launchAtStartup),
                value: autoStart,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).toggleAutoStart(value),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile.adaptive(
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
      ],
    );
  }
}
