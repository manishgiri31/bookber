import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

class BBTheme {
  BBTheme._();

  static ThemeData dark() {
    return _build(Brightness.dark);
  }

  static ThemeData light() {
    return _build(Brightness.light);
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bgCanvas = isDark ? BBColors.bgCanvas : BBColors.bgCanvasLight;
    final bgSurface = isDark ? BBColors.bgSurface : BBColors.bgSurfaceLight;
    final bgElevated = isDark ? BBColors.bgElevated : BBColors.bgElevatedLight;
    final textPrimary = isDark ? BBColors.textPrimary : BBColors.textPrimaryLight;
    final textSecondary = isDark ? BBColors.textSecondary : BBColors.textSecondaryLight;
    final borderColor = isDark ? BBColors.borderDefault : BBColors.borderDefaultLight;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: BBColors.brandPrimary,
            primaryContainer: BBColors.brandPrimaryDim,
            secondary: BBColors.brandSecondary,
            surface: BBColorPrimitives.neutral100,
            onPrimary: BBColorPrimitives.neutral50,
            onSecondary: BBColorPrimitives.neutral50,
            onSurface: BBColorPrimitives.neutral900,
            error: BBColors.error,
            onError: BBColorPrimitives.neutral1000,
          )
        : const ColorScheme.light(
            primary: BBColors.brandPrimary,
            primaryContainer: BBColors.brandPrimaryDim,
            secondary: BBColors.brandSecondary,
            surface: BBColorPrimitives.neutral1000,
            onPrimary: BBColorPrimitives.neutral1000,
            onSecondary: BBColorPrimitives.neutral1000,
            onSurface: BBColorPrimitives.neutral50,
            error: BBColors.error,
            onError: BBColorPrimitives.neutral1000,
          );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgCanvas,
      canvasColor: bgCanvas,

      // Text theme
      textTheme: TextTheme(
        displayLarge: BBTypography.displayL.copyWith(color: textPrimary),
        displayMedium: BBTypography.displayM.copyWith(color: textPrimary),
        displaySmall: BBTypography.displayS.copyWith(color: textPrimary),
        headlineLarge: BBTypography.headingL.copyWith(color: textPrimary),
        headlineMedium: BBTypography.headingM.copyWith(color: textPrimary),
        headlineSmall: BBTypography.headingS.copyWith(color: textPrimary),
        titleLarge: BBTypography.headingL.copyWith(color: textPrimary),
        titleMedium: BBTypography.headingM.copyWith(color: textPrimary),
        titleSmall: BBTypography.headingS.copyWith(color: textPrimary),
        bodyLarge: BBTypography.bodyL.copyWith(color: textPrimary),
        bodyMedium: BBTypography.bodyM.copyWith(color: textSecondary),
        bodySmall: BBTypography.bodyS.copyWith(color: textSecondary),
        labelLarge: BBTypography.labelL.copyWith(color: textPrimary),
        labelMedium: BBTypography.labelM.copyWith(color: textSecondary),
        labelSmall: BBTypography.labelS.copyWith(color: textSecondary),
      ),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: textPrimary, size: BBIconSize.lg),
        actionsIconTheme: IconThemeData(color: textPrimary, size: BBIconSize.lg),
        titleTextStyle: BBTypography.headingL.copyWith(color: textPrimary),
        centerTitle: false,
        titleSpacing: BBSpacing.px20,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.px16,
          vertical: BBSpacing.px16,
        ),
        hintStyle: BBTypography.bodyM.copyWith(color: textSecondary),
        labelStyle: BBTypography.bodyM.copyWith(color: textSecondary),
        floatingLabelStyle: BBTypography.labelM.copyWith(color: BBColors.brandPrimary),
        errorStyle: BBTypography.labelS.copyWith(color: BBColors.error),
        enabledBorder: OutlineInputBorder(
          borderRadius: BBRadius.md,
          borderSide: BorderSide(color: borderColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BBRadius.md,
          borderSide: const BorderSide(color: BBColors.brandPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BBRadius.md,
          borderSide: const BorderSide(color: BBColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BBRadius.md,
          borderSide: const BorderSide(color: BBColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BBRadius.md,
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.4), width: 1.0),
        ),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BBColors.brandPrimary,
          foregroundColor: BBColorPrimitives.neutral50,
          disabledBackgroundColor: BBColors.brandPrimary.withValues(alpha: 0.4),
          disabledForegroundColor: BBColorPrimitives.neutral50.withValues(alpha: 0.5),
          minimumSize: const Size(double.infinity, BBTouchTarget.button),
          shape: const RoundedRectangleBorder(borderRadius: BBRadius.pill),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: BBTypography.button,
          padding: BBSpacing.buttonPadding,
          animationDuration: BBMotion.fast,
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: borderColor, width: 1.0),
          minimumSize: const Size(double.infinity, BBTouchTarget.button),
          shape: const RoundedRectangleBorder(borderRadius: BBRadius.pill),
          elevation: 0,
          textStyle: BBTypography.button,
          padding: BBSpacing.buttonPadding,
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BBColors.brandPrimary,
          textStyle: BBTypography.labelL.copyWith(color: BBColors.brandPrimary),
          minimumSize: const Size(0, BBTouchTarget.buttonSmall),
          padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px12, vertical: BBSpacing.px8),
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: bgSurface,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BBRadius.card),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: bgElevated,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BBRadius.xxl),
        titleTextStyle: BBTypography.displayS.copyWith(color: textPrimary),
        contentTextStyle: BBTypography.bodyM.copyWith(color: textSecondary),
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bgElevated,
        shape: const RoundedRectangleBorder(borderRadius: BBRadius.sheet),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: isDark ? BBColors.borderStrong : BBColors.borderDefaultLight,
        dragHandleSize: const Size(36, 4),
        showDragHandle: true,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: bgSurface,
        selectedColor: BBColors.brandPrimaryDim,
        labelStyle: BBTypography.labelM.copyWith(color: textPrimary),
        secondaryLabelStyle: BBTypography.labelM.copyWith(color: BBColors.brandPrimary),
        padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px12, vertical: BBSpacing.px6),
        shape: const RoundedRectangleBorder(borderRadius: BBRadius.pill),
        side: BorderSide(color: borderColor, width: 1.0),
        elevation: 0,
        selectedShadowColor: Colors.transparent,
        showCheckmark: false,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 0,
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgSurface,
        indicatorColor: BBColors.brandPrimaryDim,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: BBColors.brandPrimary, size: BBIconSize.md);
          }
          return IconThemeData(color: textSecondary, size: BBIconSize.md);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BBTypography.labelM.copyWith(color: BBColors.brandPrimary);
          }
          return BBTypography.labelM.copyWith(color: textSecondary);
        }),
        elevation: 0,
        height: 64,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgOverlay,
        contentTextStyle: BBTypography.bodyM.copyWith(color: textPrimary),
        shape: const RoundedRectangleBorder(borderRadius: BBRadius.md),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BBColors.brandPrimary,
        linearTrackColor: BBColors.brandPrimaryDim,
        circularTrackColor: BBColors.brandPrimaryDim,
        linearMinHeight: 4.0,
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: BBColors.brandPrimaryDim,
        textColor: textPrimary,
        iconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.px16,
          vertical: BBSpacing.px4,
        ),
        minVerticalPadding: BBSpacing.px12,
        dense: false,
        shape: const RoundedRectangleBorder(borderRadius: BBRadius.md),
      ),

      // Icon theme
      iconTheme: IconThemeData(color: textPrimary, size: BBIconSize.lg),

      // Splash / ripple
      splashColor: BBColors.brandPrimaryDim,
      highlightColor: Colors.transparent,
      hoverColor: BBColors.brandPrimaryDim,

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// THEME EXTENSION — dark mode aware color accessor
// ─────────────────────────────────────────────────────────────

class BBColorTheme extends ThemeExtension<BBColorTheme> {
  const BBColorTheme({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.borderSubtle,
  });

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color border;
  final Color borderSubtle;

  static const BBColorTheme dark = BBColorTheme(
    bgCanvas: BBColors.bgCanvas,
    bgSurface: BBColors.bgSurface,
    bgElevated: BBColors.bgElevated,
    textPrimary: BBColors.textPrimary,
    textSecondary: BBColors.textSecondary,
    textDisabled: BBColors.textDisabled,
    border: BBColors.borderDefault,
    borderSubtle: BBColors.borderSubtle,
  );

  static const BBColorTheme light = BBColorTheme(
    bgCanvas: BBColors.bgCanvasLight,
    bgSurface: BBColors.bgSurfaceLight,
    bgElevated: BBColors.bgElevatedLight,
    textPrimary: BBColors.textPrimaryLight,
    textSecondary: BBColors.textSecondaryLight,
    textDisabled: BBColors.textDisabledLight,
    border: BBColors.borderDefaultLight,
    borderSubtle: BBColors.borderSubtleLight,
  );

  @override
  BBColorTheme copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? border,
    Color? borderSubtle,
  }) {
    return BBColorTheme(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
    );
  }

  @override
  BBColorTheme lerp(BBColorTheme? other, double t) {
    if (other == null) return this;
    return BBColorTheme(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }
}

// Extension for easy access
extension BBThemeContext on BuildContext {
  BBColorTheme get bbColors =>
      Theme.of(this).extension<BBColorTheme>() ?? BBColorTheme.dark;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
