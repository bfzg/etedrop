import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'language_dialog.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class AppearanceSection extends ConsumerWidget {
  final Locale? locale;

  const AppearanceSection({super.key, required this.locale});

  static String _languageSubtitle(Locale? locale, AppLocalizations l10n) {
    if (locale == null) return l10n.followSystem;
    switch (locale.languageCode) {
      case 'zh':
        return l10n.langChineseSimplified;
      case 'en':
        return l10n.langEnglish;
      case 'ja':
        return l10n.langJapanese;
      case 'ko':
        return l10n.langKorean;
      case 'es':
        return l10n.langSpanish;
      default:
        return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.appearance),
        SettingsCard(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_languageSubtitle(locale, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLanguageDialog(context, ref, locale, l10n),
          ),
        ),
      ],
    );
  }
}
