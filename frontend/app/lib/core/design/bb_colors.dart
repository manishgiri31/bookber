import 'package:flutter/material.dart';

abstract final class BBColors {
  // Brand — vibrant red accent
  static const Color amber = Color(0xFFE53935);
  static const Color amberLight = Color(0xFFEF5350);
  static const Color amberDark = Color(0xFFC62828);
  static const Color amberSurface = Color(0xFFFFEBEE);
  static const Color amberSurfaceDark = Color(0xFF3E0000);

  // Semantic
  static const Color success = Color(0xFF00C853);
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color successSurfaceDark = Color(0xFF0A2E0A);
  static const Color error = Color(0xFFE53935);
  static const Color errorSurface = Color(0xFFFFEBEE);
  static const Color errorSurfaceDark = Color(0xFF3E0000);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1E88E5);

  // Status chips
  static const Color statusQueued = Color(0xFF1E88E5);
  static const Color statusReady = Color(0xFF00C853);
  static const Color statusCalled = Color(0xFFFFA000);
  static const Color statusInService = Color(0xFF7C4DFF);
  static const Color statusCompleted = Color(0xFF757575);
  static const Color statusCancelled = Color(0xFFE53935);
  static const Color statusNoShow = Color(0xFF9E9E9E);

  // Transparent
  static const Color transparent = Colors.transparent;

  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'QUEUED':
      case 'WAITING':
        return statusQueued;
      case 'READY':
        return statusReady;
      case 'CALLED':
        return statusCalled;
      case 'IN_SERVICE':
        return statusInService;
      case 'COMPLETED':
        return statusCompleted;
      case 'CANCELLED':
        return statusCancelled;
      case 'NO_SHOW':
        return statusNoShow;
      default:
        return statusQueued;
    }
  }
}

class BBColorScheme {
  const BBColorScheme({
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceHigh,
    required this.border,
    required this.borderSubtle,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.accent,
    required this.accentForeground,
    required this.accentSurface,
    required this.shadow,
  });

  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceHigh;
  final Color border;
  final Color borderSubtle;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color accent;
  final Color accentForeground;
  final Color accentSurface;
  final Color shadow;

  static const BBColorScheme light = BBColorScheme(
    background: Color(0xFFF7F7F7),
    backgroundSecondary: Color(0xFFEEEEEE),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF5F5F5),
    surfaceHigh: Color(0xFFEDEDED),
    border: Color(0xFFE0E0E0),
    borderSubtle: Color(0xFFF0F0F0),
    text: Color(0xFF0D0D0D),
    textSecondary: Color(0xFF616161),
    textTertiary: Color(0xFF9E9E9E),
    textInverse: Color(0xFFFFFFFF),
    accent: Color(0xFFE53935),
    accentForeground: Color(0xFFFFFFFF),
    accentSurface: Color(0xFFFFEBEE),
    shadow: Color(0x1A000000),
  );

  static const BBColorScheme dark = BBColorScheme(
    background: Color(0xFF000000),
    backgroundSecondary: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    surfaceVariant: Color(0xFF1E1E1E),
    surfaceHigh: Color(0xFF282828),
    border: Color(0xFF2A2A2A),
    borderSubtle: Color(0xFF1F1F1F),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFAAAAAA),
    textTertiary: Color(0xFF666666),
    textInverse: Color(0xFF000000),
    accent: Color(0xFFE53935),
    accentForeground: Color(0xFFFFFFFF),
    accentSurface: Color(0xFF3E0000),
    shadow: Color(0x66000000),
  );
}

extension BBColorSchemeExtension on BuildContext {
  BBColorScheme get bbColors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? BBColorScheme.dark : BBColorScheme.light;
  }

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
