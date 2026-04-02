import 'dart:ui';

import '../services/local_storage_service.dart';
import 'app_localizations.dart';

const _kLocaleStorageKey = 'app_locale';

/// Effective app [Locale]: user choice from storage, otherwise system locale.
Locale resolveAppLocale() {
  final saved = LocalStorageService.instance.get<String>(_kLocaleStorageKey);
  if (saved != null && saved.isNotEmpty) {
    return Locale(saved);
  }
  return PlatformDispatcher.instance.locale;
}

/// [AppLocalizations] for the current app/system locale, falling back to English.
AppLocalizations loadAppLocalizationsSync() {
  final code = resolveAppLocale().languageCode;
  if (AppLocalizations.supportedLocales.any((l) => l.languageCode == code)) {
    return lookupAppLocalizations(Locale(code));
  }
  return lookupAppLocalizations(const Locale('en'));
}
