import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/ui/e_dialog.dart';
import '../providers/locale_provider.dart';
import 'selection_option.dart';

Future<void> showLanguageDialog(
  BuildContext context,
  WidgetRef ref,
  Locale? currentLocale,
  AppLocalizations l10n,
) async {
  // Language names should be shown in their own language (autonyms),
  // regardless of the current UI locale.
  const langNativeName = <String, String>{
    'zh': '简体中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'es': 'Español',
  };

  await showDialog<void>(
    context: context,
    builder: (context) {
      return EDialog.alert(
        title: Text(l10n.language),
        content: EDialog.formBody(
          context,
          Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectionOption(
                  title: l10n.followSystem,
                  selected: currentLocale == null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(null);
                    Navigator.of(context).pop();
                  },
                ),
                SelectionOption(
                  title: langNativeName['zh']!,
                  selected: currentLocale?.languageCode == 'zh',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('zh'));
                    Navigator.of(context).pop();
                  },
                ),
                SelectionOption(
                  title: langNativeName['en']!,
                  selected: currentLocale?.languageCode == 'en',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('en'));
                    Navigator.of(context).pop();
                  },
                ),
                SelectionOption(
                  title: langNativeName['ja']!,
                  selected: currentLocale?.languageCode == 'ja',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('ja'));
                    Navigator.of(context).pop();
                  },
                ),
                SelectionOption(
                  title: langNativeName['ko']!,
                  selected: currentLocale?.languageCode == 'ko',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('ko'));
                    Navigator.of(context).pop();
                  },
                ),
                SelectionOption(
                  title: langNativeName['es']!,
                  selected: currentLocale?.languageCode == 'es',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('es'));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
