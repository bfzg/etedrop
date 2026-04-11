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

/// 不依赖 [Ref] 的线路解析：偏好读 [_serverLineKey]（与 [ServerLinePreferenceNotifier] 一致），
/// [appLocale] 为 null 时等同未改语言设置，使用 [PlatformDispatcher.instance.locale]。
///
/// 用于 [DeviceManager] 等无法在字段初始化里 `watch` Provider 的占位，须与
/// [serverEndpointsProvider] 在相同偏好+语言下一致。
ServerEndpoints resolveServerEndpointsSync({Locale? appLocale}) {
  final raw = LocalStorageService.instance.get<String>(_serverLineKey);
  final pref = raw == null
      ? ServerLinePreference.auto
      : ServerLinePreference.values.firstWhere(
          (e) => e.name == raw,
          orElse: () => ServerLinePreference.auto,
        );
  return ServerEndpoints.resolve(
    preference: pref,
    resolvedLocale: _resolvedLocale(appLocale),
  );
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
