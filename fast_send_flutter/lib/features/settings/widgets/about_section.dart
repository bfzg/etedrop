import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/constants.dart';
import '../../../core/update/update_service.dart';
import '../../../core/update/update_state.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasUpdate = ref.watch(updateStateProvider).hasUpdate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.about),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(AppConstants.appName),
                subtitle: Text('v${AppConstants.version}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: Text(l10n.checkForUpdates),
                subtitle: Text(l10n.checkForUpdatesDesc),
                trailing: hasUpdate
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () => UpdateService.instance.checkAndPrompt(context, ref: ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
