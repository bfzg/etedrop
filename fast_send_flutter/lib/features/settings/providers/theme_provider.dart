import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../services/local_storage_service.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const _themeKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    // 启动时从本地存储读取主题设置
    final savedMode = LocalStorageService.instance.get<String>(_themeKey);
    return _parseThemeMode(savedMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await LocalStorageService.instance.set<String>(_themeKey, mode.toString());
  }

  ThemeMode _parseThemeMode(String? mode) {
    return ThemeMode.light;
  }
}
