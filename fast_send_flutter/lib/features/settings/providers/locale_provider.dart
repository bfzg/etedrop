import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../services/local_storage_service.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const _localeKey = 'app_locale';

  @override
  Locale? build() {
    final savedLocale = LocalStorageService.instance.get<String>(_localeKey);
    return _parseLocale(savedLocale);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await LocalStorageService.instance.remove(_localeKey);
    } else {
      await LocalStorageService.instance.set<String>(_localeKey, locale.languageCode);
    }
  }

  Locale? _parseLocale(String? code) {
    if (code == null) return null; // Follow system
    return Locale(code);
  }
}
