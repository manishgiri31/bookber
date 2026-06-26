import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bb_colors.dart';
import 'bb_tokens.dart';
import 'bb_typography.dart';

abstract final class BBTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? BBColorScheme.dark : BBColorScheme.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.accentForeground,
      primaryContainer: colors.accentSurface,
      onPrimaryContainer: colors.text,
      secondary: colors.textSecondary,
      onSecondary: colors.textInverse,
      secondaryContainer: colors.surfaceVariant,
      onSecondaryContainer: colors.text,
      tertiary: BBColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: colors.surfaceVariant,
      onTertiaryContainer: colors.text,
      error: BBColors.error,
      onError: Colors.white,
      errorContainer: isDark ? BBColors.errorSurfaceDark : BBColors.errorSurface,
      onErrorContainer: BBColors.error,
      surface: colors.surface,
      onSurface: colors.text,
      surfaceContainerHighest: colors.surfaceHigh,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.border,
      outlineVariant: colors.borderSubtle,
      shadow: isDark ? const Color(0xFF000000) : const Color(0x14000000),
      scrim: Colors.black,
      inverseSurface: isDark ? colors.surface : const Color(0xFF1A1A1A),
      onInverseSurface: isDark ? colors.text : const Color(0xFFFFFFFF),
      inversePrimary: colors.accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: BBTypography.textTheme.apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: BBTypography.textTheme.titleLarge?.copyWith(
          color: colors.text,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: colors.text, size: 22),
        actionsIconTheme: IconThemeData(color: colors.text, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 2,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BBRadius.xl),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BBRadius.xl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BBRadius.xl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BBRadius.xl),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BBRadius.xl),
          borderSide: const BorderSide(color: BBColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BBRadius.xl),
          borderSide: const BorderSide(color: BBColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.base,
          vertical: BBSpacing.md,
        ),
        hintStyle: BBTypography.textTheme.bodyMedium?.copyWith(
          color: colors.textTertiary,
        ),
        labelStyle: BBTypography.textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
        errorStyle: BBTypography.textTheme.bodySmall?.copyWith(
          color: BBColors.error,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.accentForeground,
          disabledBackgroundColor: isDark
              ? const Color(0xFF2D2D2D)
              : const Color(0xFFD1D5DB),
          disabledForegroundColor: colors.textTertiary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BBRadius.full),
          ),
          minimumSize: const Size(double.infinity, 56),
          textStyle: BBTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: BBSpacing.xl),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BBRadius.full),
          ),
          minimumSize: const Size(double.infinity, 56),
          textStyle: BBTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: BBSpacing.xl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: BBTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BBRadius.full),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        selectedColor: colors.accent,
        disabledColor: colors.surfaceVariant,
        labelStyle: BBTypography.textTheme.labelMedium?.copyWith(
          color: colors.text,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BBRadius.full),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.md,
          vertical: BBSpacing.xs,
        ),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 0.5,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textTertiary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.accent, size: 22);
          }
          return IconThemeData(color: colors.textTertiary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = BBTypography.textTheme.labelSmall!;
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w700,
            );
          }
          return base.copyWith(color: colors.textTertiary);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surfaceHigh : const Color(0xFF1A1A1A),
        contentTextStyle: BBTypography.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BBRadius.xl),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BBRadius.xl),
        ),
        titleTextStyle: BBTypography.textTheme.headlineSmall?.copyWith(
          color: colors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BBRadius.xxl),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BBRadius.lg),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.base,
          vertical: BBSpacing.xs,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.accentForeground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BBRadius.full),
        ),
      ),
      iconTheme: IconThemeData(color: colors.textSecondary, size: 20),
    );
  }
}

extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
