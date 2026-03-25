import 'package:flutter/material.dart';

class AppStyles {
  AppStyles._();

  static const Color primary = Color(0xFF0052D9);

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
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
    );
  }
}

