import 'package:flutter/material.dart';

import '../design/tokens.dart';

class BookerSnackbar {
  static void _show(
    BuildContext context,
    String message, {
    required Color accentColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: BBColors.bgElevated,
        content: Row(
          children: [
            Icon(icon, color: accentColor, size: BBIconSize.md),
            const SizedBox(width: BBSpacing.px12),
            Expanded(
              child: Text(
                message,
                style: BBTypography.bodyM.copyWith(color: BBColors.textPrimary),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BBRadius.md),
        margin: const EdgeInsets.all(BBSpacing.px16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void success(BuildContext context, String message) => _show(
        context,
        message,
        accentColor: BBColors.success,
        icon: Icons.check_circle_outline_rounded,
      );

  static void error(BuildContext context, String message) => _show(
        context,
        message,
        accentColor: BBColors.error,
        icon: Icons.error_outline_rounded,
      );

  static void info(BuildContext context, String message) => _show(
        context,
        message,
        accentColor: BBColors.brandPrimary,
        icon: Icons.info_outline_rounded,
      );

  static void warning(BuildContext context, String message) => _show(
        context,
        message,
        accentColor: BBColors.warning,
        icon: Icons.warning_amber_rounded,
      );
}
