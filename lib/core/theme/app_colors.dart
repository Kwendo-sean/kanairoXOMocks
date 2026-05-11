import 'package:flutter/material.dart';

class AppColors {
  // ── BRAND COLORS (Senior Engineer Update) ──
  static const Color primary = Color(0xFF9B111E); // Crimson Red
  static const Color nearBlack = Color(0xFF1A1A1A);
  static const Color warmBeige = Color(0xFFFAF7F4); // Warm Beige background
  static const Color softTan = Color(0xFFE8E0D0); // Divider/Progress color
  
  static const Color primaryLight = Color(0xFFB22222);
  static const Color primaryGlass = Color(0x149B111E);
  static const Color background = Color(0xFFFAF7F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color(0xF5FFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFFA0A0A0);
  static const Color border = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFF0F0F0);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  
  // ── DARK MODE constants ────────
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1C1612);
  static const Color darkSurface2 = Color(0xFF252018);
  static const Color darkPrimary = Color(0xFFC0394B);
  static const Color darkPrimaryGlass = Color(0x26C0394B);
  static const Color darkTextPrimary = Color(0xFFF5EFE6);
  static const Color darkTextSecondary = Color(0xFFC4B8AE);
  static const Color darkTextMuted = Color(0xFF7A6E66);
  static const Color darkBorder = Color(0xFF2E2820);
  static const Color darkSurfaceGlass = Color(0x1AFFFFFF);
  
  // ── THEME-AWARE HELPERS ────────────────────
  static Color themePrimary(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
      ? darkPrimary : primary;
  
  static Color themeBackground(BuildContext ctx) =>
    Theme.of(ctx).scaffoldBackgroundColor;
  
  static Color themeSurface(BuildContext ctx) =>
    Theme.of(ctx).cardColor;
  
  static Color themeTextPrimary(BuildContext ctx) =>
    Theme.of(ctx).colorScheme.onSurface;
  
  static Color themeTextMuted(BuildContext ctx) =>
    Theme.of(ctx).colorScheme.onSurface
      .withOpacity(0.5);
  
  static Color themePrimaryGlass(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
      ? darkPrimaryGlass : primaryGlass;
  
  static Color themeBorder(BuildContext ctx) =>
    Theme.of(ctx).dividerColor;
}
