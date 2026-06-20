import 'package:flutter/material.dart';

import '../design/bb_colors.dart';
import '../design/bb_tokens.dart';
import '../design/bb_typography.dart';
import 'bb_button.dart';

class BBEmptyState extends StatelessWidget {
  const BBEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: colors.textTertiary),
              ),
              const SizedBox(height: BBSpacing.lg),
            ],
            Text(
              title,
              style: BBTypography.textTheme.headlineSmall?.copyWith(
                color: colors.text,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: BBSpacing.sm),
              Text(
                subtitle!,
                style: BBTypography.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: BBSpacing.xl),
              BBButton(
                label: actionLabel!,
                onPressed: action,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
