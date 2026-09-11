import 'package:flutter/material.dart';

class AppStyles {
  AppStyles._();

  static const Color primary = Color(0xFF0052D9);

  /// 全局 UI 字体（需在 [pubspec.yaml] 的 `fonts` 中注册同名 family）。
  static const String fontFamily = 'Inter';

  /// 西文字体不含 CJK 字形时的系统回退（顺序依次尝试）。
  static const List<String> fontFamilyFallback = [
    'PingFang SC',
    'Hiragino Sans GB',
    'Microsoft YaHei',
    'Apple SD Gothic Neo',
  ];

  static ColorScheme lightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: const Color(0xFFF7F7F7),
      surfaceContainerHighest: const Color(0xFFEEEEEE),
    );
  }

  static ThemeData lightTheme() {
    final scheme = lightColorScheme();
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEAEAEA),
        thickness: 1,
      ),
    );

    // 保证 TextTheme / PrimaryTextTheme 均带上 fontFamily（含组件库内部样式）。
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      ),
    );
  }
}
