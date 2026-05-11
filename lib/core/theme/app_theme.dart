import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAF7F4),
        primaryColor: const Color(0xFF8B1A1A),
        colorScheme: const ColorScheme.light(
            primary: Color(0xFF8B1A1A),
            surface: Color(0xFFFFFFFF),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1A1A1A),
            onSurfaceVariant: Color(0xFFA0A0A0)),
        fontFamily: 'DMSans',
        appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFAF7F4),
            foregroundColor: Color(0xFF1A1A1A),
            elevation: 0,
            centerTitle: true),
        cardColor: const Color(0xFFFFFFFF),
        dividerColor: const Color(0xFFEEEEEE),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFFFAF7F4),
            selectedItemColor: Color(0xFF8B1A1A),
            unselectedItemColor: Color(0xFFA0A0A0)));

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: const Color(0xFFC0394B),
        colorScheme: const ColorScheme.dark(
            primary: Color(0xFFC0394B),
            surface: Color(0xFF1C1612),
            onPrimary: Colors.white,
            onSurface: Color(0xFFF5EFE6),
            onSurfaceVariant: Color(0xFF7A6E66)),
        fontFamily: 'DMSans',
        appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0D0D0D),
            foregroundColor: Color(0xFFF5EFE6),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF5EFE6))),
        cardColor: const Color(0xFF1C1612),
        dividerColor: const Color(0xFF2E2820),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1C1612),
            selectedItemColor: Color(0xFFC0394B),
            unselectedItemColor: Color(0xFF7A6E66)));
}

extension ThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get primaryColor => Theme.of(this).primaryColor;
  Color get bgColor => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).cardColor;
  Color get textColor => Theme.of(this).colorScheme.onSurface;
  Color get mutedColor => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get borderColor => Theme.of(this).dividerColor;
}
