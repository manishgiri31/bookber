import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BookerSnackbar {
  static void _show(BuildContext context, String message, {required Color borderColor, required IconData icon}) {
    final snack = SnackBar(
      backgroundColor: AppColors.bgSecondary,
      content: Row(
        children: [
          Icon(icon, color: borderColor),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  static void success(BuildContext context, String message) => _show(context, message, borderColor: AppColors.success, icon: Icons.check_circle);
  static void error(BuildContext context, String message) => _show(context, message, borderColor: AppColors.error, icon: Icons.error);
  static void info(BuildContext context, String message) => _show(context, message, borderColor: AppColors.accentPrimary, icon: Icons.info);
  static void warning(BuildContext context, String message) => _show(context, message, borderColor: AppColors.warning, icon: Icons.warning);
}
