import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// COLOR PRIMITIVES
// ─────────────────────────────────────────────────────────────

class BBColorPrimitives {
  BBColorPrimitives._();

  // Neutrals — obsidian scale
  static const Color neutral0 = Color(0xFF000000);
  static const Color neutral50 = Color(0xFF0D0D0F);
  static const Color neutral100 = Color(0xFF141417);
  static const Color neutral150 = Color(0xFF1C1C21);
  static const Color neutral200 = Color(0xFF242429);
  static const Color neutral300 = Color(0xFF2E2E35);
  static const Color neutral400 = Color(0xFF4A4A5A);
  static const Color neutral500 = Color(0xFF6B6B7B);
  static const Color neutral600 = Color(0xFF8A8A9A);
  static const Color neutral700 = Color(0xFFB4B4C4);
  static const Color neutral800 = Color(0xFFD4D4E4);
  static const Color neutral900 = Color(0xFFF5F5F7);
  static const Color neutral1000 = Color(0xFFFFFFFF);

  // Teal — brand primary
  static const Color teal50 = Color(0xFF003D38);
  static const Color teal100 = Color(0xFF005A52);
  static const Color teal200 = Color(0xFF007A6E);
  static const Color teal300 = Color(0xFF009B8C);
  static const Color teal400 = Color(0xFF00C2AE);
  static const Color teal500 = Color(0xFF00E5C3);
  static const Color teal600 = Color(0xFF33EBCD);
  static const Color teal700 = Color(0xFF66F0D8);
  static const Color teal800 = Color(0xFF99F5E3);
  static const Color teal900 = Color(0xFFCCFAF1);

  // Coral — secondary accent
  static const Color coral400 = Color(0xFFE84E1A);
  static const Color coral500 = Color(0xFFFF6B35);
  static const Color coral600 = Color(0xFFFF8A5C);

  // Semantic
  static const Color green400 = Color(0xFF16A34A);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF4ADE80);
  static const Color amber400 = Color(0xFFD97706);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFFBBF24);
  static const Color red400 = Color(0xFFDC2626);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFF87171);
}

// ─────────────────────────────────────────────────────────────
// SEMANTIC COLOR ROLES
// ─────────────────────────────────────────────────────────────

class BBColors {
  BBColors._();

  // Backgrounds
  static const Color bgCanvas = BBColorPrimitives.neutral50;
  static const Color bgSurface = BBColorPrimitives.neutral100;
  static const Color bgElevated = BBColorPrimitives.neutral150;
  static const Color bgOverlay = BBColorPrimitives.neutral200;

  // Light mode backgrounds
  static const Color bgCanvasLight = Color(0xFFF8F8FA);
  static const Color bgSurfaceLight = Color(0xFFFFFFFF);
  static const Color bgElevatedLight = Color(0xFFF2F2F5);
  static const Color bgOverlayLight = Color(0xFFE8E8EE);

  // Brand
  static const Color brandPrimary = BBColorPrimitives.teal500;
  static const Color brandPrimaryDim = Color(0x2600E5C3); // 15% opacity
  static const Color brandPrimaryGlow = Color(0x4D00E5C3); // 30% opacity
  static const Color brandSecondary = BBColorPrimitives.coral500;

  // Text — dark
  static const Color textPrimary = BBColorPrimitives.neutral900;
  static const Color textSecondary = BBColorPrimitives.neutral600;
  static const Color textDisabled = BBColorPrimitives.neutral400;
  static const Color textInverse = BBColorPrimitives.neutral50;
  static const Color textBrand = BBColorPrimitives.teal500;

  // Text — light
  static const Color textPrimaryLight = Color(0xFF0D0D0F);
  static const Color textSecondaryLight = Color(0xFF4A4A5A);
  static const Color textDisabledLight = Color(0xFFB4B4C4);

  // Borders
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% white
  static const Color borderDefault = Color(0x1FFFFFFF); // 12% white
  static const Color borderStrong = Color(0x33FFFFFF); // 20% white
  static const Color borderBrand = BBColorPrimitives.teal500;

  static const Color borderSubtleLight = Color(0x14000000);
  static const Color borderDefaultLight = Color(0x1F000000);

  // Status
  static const Color success = BBColorPrimitives.green500;
  static const Color successDim = Color(0x2622C55E);
  static const Color warning = BBColorPrimitives.amber500;
  static const Color warningDim = Color(0x26F59E0B);
  static const Color error = BBColorPrimitives.red500;
  static const Color errorDim = Color(0x26EF4444);

  // Queue severity
  static const Color queueFast = BBColorPrimitives.green500;
  static const Color queueBusy = BBColorPrimitives.amber500;
  static const Color queueHeavy = BBColorPrimitives.red500;

  // Scrim / Overlay
  static const Color scrim = Color(0xCC000000); // 80%
  static const Color scrimLight = Color(0x80000000); // 50%

  static Color queueColor(int waitMinutes) {
    if (waitMinutes <= 8) return queueFast;
    if (waitMinutes <= 18) return queueBusy;
    return queueHeavy;
  }
}

// ─────────────────────────────────────────────────────────────
// SPACING SCALE
// ─────────────────────────────────────────────────────────────

class BBSpacing {
  BBSpacing._();

  static const double px2 = 2.0;
  static const double px4 = 4.0;
  static const double px6 = 6.0;
  static const double px8 = 8.0;
  static const double px10 = 10.0;
  static const double px12 = 12.0;
  static const double px14 = 14.0;
  static const double px16 = 16.0;
  static const double px20 = 20.0;
  static const double px24 = 24.0;
  static const double px28 = 28.0;
  static const double px32 = 32.0;
  static const double px40 = 40.0;
  static const double px48 = 48.0;
  static const double px56 = 56.0;
  static const double px64 = 64.0;
  static const double px80 = 80.0;
  static const double px96 = 96.0;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: px20);
  static const EdgeInsets cardPadding = EdgeInsets.all(px20);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(px16);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: px24, vertical: px16);
}

// ─────────────────────────────────────────────────────────────
// BORDER RADIUS SCALE
// ─────────────────────────────────────────────────────────────

class BBRadius {
  BBRadius._();

  static const double r4 = 4.0;
  static const double r6 = 6.0;
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;
  static const double rFull = 999.0;

  static const BorderRadius xs = BorderRadius.all(Radius.circular(r6));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius card = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(rFull));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(r24));
}

// ─────────────────────────────────────────────────────────────
// ELEVATION / SHADOW SYSTEM
// ─────────────────────────────────────────────────────────────

class BBElevation {
  BBElevation._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 48,
      offset: Offset(0, 24),
    ),
  ];

  static List<BoxShadow> brandGlow(Color color, {double intensity = 0.3}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────
// TYPOGRAPHY SCALE
// ─────────────────────────────────────────────────────────────

class BBTypography {
  BBTypography._();

  // Display — Satoshi Bold, tight tracking
  static const TextStyle displayXL = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.1,
    color: BBColors.textPrimary,
  );

  static const TextStyle displayL = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.15,
    color: BBColors.textPrimary,
  );

  static const TextStyle displayM = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
    color: BBColors.textPrimary,
  );

  static const TextStyle displayS = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.25,
    color: BBColors.textPrimary,
  );

  // Heading — Satoshi Semibold
  static const TextStyle headingL = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.3,
    color: BBColors.textPrimary,
  );

  static const TextStyle headingM = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
    color: BBColors.textPrimary,
  );

  static const TextStyle headingS = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: BBColors.textPrimary,
  );

  // Body — DM Sans Regular
  static const TextStyle bodyL = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: BBColors.textPrimary,
  );

  static const TextStyle bodyM = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: BBColors.textSecondary,
  );

  static const TextStyle bodyS = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: BBColors.textSecondary,
  );

  // Label — DM Sans Medium
  static const TextStyle labelL = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: BBColors.textPrimary,
  );

  static const TextStyle labelM = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
    color: BBColors.textPrimary,
  );

  static const TextStyle labelS = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.4,
    color: BBColors.textSecondary,
  );

  // Numeric — Satoshi Bold for queue numbers
  static const TextStyle numericXL = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 64,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.0,
    height: 1.0,
    color: BBColors.textPrimary,
  );

  static const TextStyle numericL = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.0,
    color: BBColors.textPrimary,
  );

  static const TextStyle numericM = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.0,
    color: BBColors.textPrimary,
  );

  // Button labels
  static const TextStyle button = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.0,
  );

  static const TextStyle buttonS = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.0,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
    color: BBColors.textDisabled,
  );

  // Overline
  static const TextStyle overline = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.4,
    color: BBColors.textSecondary,
  );
}

// ─────────────────────────────────────────────────────────────
// MOTION / ANIMATION SYSTEM
// ─────────────────────────────────────────────────────────────

class BBMotion {
  BBMotion._();

  // Durations
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration xslow = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 300);
  static const Duration modal = Duration(milliseconds: 350);
  static const Duration pulse = Duration(milliseconds: 1400);

  // Curves
  static const Curve spring = Curves.easeOutBack;
  static const Curve smooth = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve emphasize = Cubic(0.2, 0.0, 0.0, 1.0);

  // Stagger delay for list items
  static Duration stagger(int index, {Duration base = const Duration(milliseconds: 40)}) {
    return Duration(milliseconds: base.inMilliseconds * index);
  }
}

// ─────────────────────────────────────────────────────────────
// ICON SIZES
// ─────────────────────────────────────────────────────────────

class BBIconSize {
  BBIconSize._();

  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 28.0;
  static const double xxl = 32.0;
}

// ─────────────────────────────────────────────────────────────
// TOUCH TARGET SIZES
// ─────────────────────────────────────────────────────────────

class BBTouchTarget {
  BBTouchTarget._();

  static const double minimum = 44.0; // WCAG minimum
  static const double button = 56.0;
  static const double buttonSmall = 44.0;
  static const double icon = 44.0;
  static const double navItem = 48.0;
}
