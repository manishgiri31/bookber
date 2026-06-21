import 'package:flutter/material.dart';

abstract final class BBColors {
  // Brand
  static const Color amber = Color(0xFFDC2626);
  static const Color amberLight = Color(0xFFEF4444);
  static const Color amberDark = Color(0xFFB91C1C);
  static const Color amberSurface = Color(0xFFFEE2E2);
  static const Color amberSurfaceDark = Color(0xFF450A0A);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFD1FAE5);
  static const Color successSurfaceDark = Color(0xFF052E16);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color errorSurfaceDark = Color(0xFF2D0707);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Status chips
  static const Color statusQueued = Color(0xFF3B82F6);
  static const Color statusReady = Color(0xFF10B981);
  static const Color statusCalled = Color(0xFFF59E0B);
  static const Color statusInService = Color(0xFF8B5CF6);
  static const Color statusCompleted = Color(0xFF6B7280);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusNoShow = Color(0xFF9CA3AF);

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

  static const BBColorScheme light = BBColorScheme(
    background: Color(0xFFF8F8F8),
    backgroundSecondary: Color(0xFFF0EFEB),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF5F4F0),
    surfaceHigh: Color(0xFFEEEDE9),
    border: Color(0xFFE5E5E5),
    borderSubtle: Color(0xFFF0F0F0),
    text: Color(0xFF0A0A0B),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    textInverse: Color(0xFFFFFFFF),
    accent: Color(0xFFDC2626),
    accentForeground: Color(0xFFFFFFFF),
    accentSurface: Color(0xFFFEE2E2),
  );

  static const BBColorScheme dark = BBColorScheme(
    background: Color(0xFF09090B),
    backgroundSecondary: Color(0xFF0D0D0F),
    surface: Color(0xFF111113),
    surfaceVariant: Color(0xFF1A1A1C),
    surfaceHigh: Color(0xFF242426),
    border: Color(0xFF27272A),
    borderSubtle: Color(0xFF1E1E21),
    text: Color(0xFFFAFAFA),
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280),
    textInverse: Color(0xFF0A0A0B),
    accent: Color(0xFFDC2626),
    accentForeground: Color(0xFFFFFFFF),
    accentSurface: Color(0xFF450A0A),
  );
}

extension BBColorSchemeExtension on BuildContext {
  BBColorScheme get bbColors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? BBColorScheme.dark : BBColorScheme.light;
  }

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
