import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'selection_option.dart';

Future<void> showLanguageDialog(
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
          SelectionOption(
            title: l10n.followSystem,
            selected: currentLocale == null,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(null);
              Navigator.of(context).pop();
            },
          ),
          SelectionOption(
            title: '简体中文',
            selected: currentLocale?.languageCode == 'zh',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('zh'));
              Navigator.of(context).pop();
            },
          ),
          SelectionOption(
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
