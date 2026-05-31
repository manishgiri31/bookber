import 'package:flutter/material.dart';

import 'design_system.dart';

class AppTheme {
  static Color get searchSurface => BookBerPalette.bgElevated;
  static Color get liveIndicator => BookBerPalette.liveGlow;
  static Color get primaryAccent => BookBerPalette.primaryAccent;
  static Color get operationalAccent => BookBerPalette.operationalAccent;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BookBerPalette.primaryAccent,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: BookBerPalette.primaryAccent,
        secondary: BookBerPalette.operationalAccent,
        surface: BookBerPalette.bgSurface,
        error: BookBerPalette.urgentRed,
      ),
      scaffoldBackgroundColor: BookBerPalette.bgPrimary,
      cardTheme: CardThemeData(
        elevation: 0,
        color: BookBerPalette.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: BookBerTypography.light(),
      appBarTheme: const AppBarTheme(
        backgroundColor: BookBerPalette.bgSurface,
        foregroundColor: BookBerPalette.textPrimary,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BookBerPalette.primaryAccent,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: BookBerPalette.primaryAccent,
        secondary: BookBerPalette.operationalAccent,
        surface: BookBerPalette.bgSurface,
        error: BookBerPalette.urgentRed,
      ),
      scaffoldBackgroundColor: BookBerPalette.bgPrimary,
      cardTheme: CardThemeData(
        elevation: 0,
        color: BookBerPalette.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: BookBerTypography.dark(),
      appBarTheme: const AppBarTheme(
        backgroundColor: BookBerPalette.bgSurface,
        foregroundColor: BookBerPalette.textPrimary,
        elevation: 0,
      ),
    );
  }
}
