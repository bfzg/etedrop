import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'language_dialog.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class AppearanceSection extends ConsumerWidget {
  final Locale? locale;

  const AppearanceSection({super.key, required this.locale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        SettingsSectionHeader(title: l10n.appearance),
        SettingsCard(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              locale?.languageCode == 'zh'
                  ? '简体中文'
                  : (locale?.languageCode == 'en' ? 'English' : l10n.followSystem),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLanguageDialog(context, ref, locale, l10n),
          ),
        ),
      ],
    );
  }
}
