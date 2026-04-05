import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/server_endpoints.dart';
import '../../../services/local_storage_service.dart';
import 'locale_provider.dart';

part 'server_line_provider.g.dart';

const _serverLineKey = 'server_line_preference';

@riverpod
class ServerLinePreferenceNotifier extends _$ServerLinePreferenceNotifier {
  @override
  ServerLinePreference build() {
    final raw = LocalStorageService.instance.get<String>(_serverLineKey);
    if (raw == null) return ServerLinePreference.auto;
    return ServerLinePreference.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ServerLinePreference.auto,
    );
  }

  Future<void> setPreference(ServerLinePreference value) async {
    state = value;
    await LocalStorageService.instance.set<String>(_serverLineKey, value.name);
  }
}

/// 解析界面语言：与语言设置一致（null = 跟系统）
Locale _resolvedLocale(Locale? appLocale) {
  if (appLocale != null) return appLocale;
  return PlatformDispatcher.instance.locale;
}

@riverpod
ServerEndpoints serverEndpoints(Ref ref) {
  final pref = ref.watch(serverLinePreferenceProvider);
  final appLocale = ref.watch(localeProvider);
  return ServerEndpoints.resolve(
    preference: pref,
    resolvedLocale: _resolvedLocale(appLocale),
  );
}
