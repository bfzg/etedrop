import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/server_endpoints.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/server_line_provider.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class NetworkLineSection extends ConsumerWidget {
  const NetworkLineSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pref = ref.watch(serverLinePreferenceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.networkLine),
        SettingsCard(
          child: Column(
            children: [
              RadioListTile<ServerLinePreference>(
                title: Text(l10n.serverLineAuto),
                value: ServerLinePreference.auto,
                groupValue: pref,
                onChanged: (v) {
                  if (v != null) {
                    ref
                        .read(serverLinePreferenceProvider.notifier)
                        .setPreference(v);
                  }
                },
              ),
              RadioListTile<ServerLinePreference>(
                title: Text(l10n.serverLineGlobal),
                value: ServerLinePreference.global,
                groupValue: pref,
                onChanged: (v) {
                  if (v != null) {
                    ref
                        .read(serverLinePreferenceProvider.notifier)
                        .setPreference(v);
                  }
                },
              ),
              RadioListTile<ServerLinePreference>(
                title: Text(l10n.serverLineMainland),
                value: ServerLinePreference.mainland,
                groupValue: pref,
                onChanged: (v) {
                  if (v != null) {
                    ref
                        .read(serverLinePreferenceProvider.notifier)
                        .setPreference(v);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
