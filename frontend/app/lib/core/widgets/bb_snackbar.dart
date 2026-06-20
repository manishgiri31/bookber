import 'package:flutter/material.dart';

import '../design/bb_colors.dart';
import '../design/bb_tokens.dart';
import '../design/bb_typography.dart';

void showBBSnackbar(
  BuildContext context, {
  required String message,
  bool isError = false,
  bool isSuccess = false,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : isSuccess
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
            size: 18,
            color: isError
                ? BBColors.error
                : isSuccess
                    ? BBColors.success
                    : BBColors.amber,
          ),
          const SizedBox(width: BBSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: BBTypography.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1A1A1C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BBRadius.md),
      ),
      margin: const EdgeInsets.all(BBSpacing.base),
    ),
  );
}
