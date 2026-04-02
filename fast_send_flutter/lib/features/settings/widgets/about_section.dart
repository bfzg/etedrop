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
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppConstants.appName),
            subtitle: Text('v${AppConstants.version}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasUpdate)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                TextButton(
                  onPressed: () =>
                      UpdateService.instance.checkAndPrompt(context, ref: ref),
                  child: Text(l10n.checkForUpdates),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
