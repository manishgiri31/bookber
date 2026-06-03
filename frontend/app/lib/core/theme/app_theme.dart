import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bgPrimary = Color(0xFF0D0D0F);
  static const Color bgSecondary = Color(0xFF141417);
  static const Color bgTertiary = Color(0xFF1C1C21);
  
  // Accents
  static const Color accentPrimary = Color(0xFF00E5C3); // electric teal
  static const Color accentGlow = Color(0x6600E5C3); // 25% opacity
  static const Color accentSecondary = Color(0xFFFF6B35); // warm coral
  
  // Text
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color textTertiary = Color(0xFF4A4A5A);
  
  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark();

    final colorScheme = ColorScheme.dark(
      primary: AppColors.accentPrimary,
      primaryContainer: AppColors.accentPrimary,
      secondary: AppColors.accentPrimary,
      background: AppColors.bgPrimary,
      surface: AppColors.bgSecondary,
      onPrimary: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      brightness: Brightness.dark,
      // Text theme per design tokens
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Satoshi', fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontFamily: 'Satoshi', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        displaySmall: TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodySmall: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        labelLarge: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        labelSmall: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textTertiary),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.accentPrimary),
        titleTextStyle: TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        centerTitle: false,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: 'DM Sans'),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontFamily: 'DM Sans'),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x0FFFFFFF), width: 1), // subtle border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: AppColors.bgPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          elevation: 0,
        ),
      ),

      cardColor: AppColors.bgSecondary,
      cardTheme: const CardThemeData(
        color: AppColors.bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        selectedItemColor: AppColors.accentPrimary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 0,
        showUnselectedLabels: false,
      ),
    );
  }
}
