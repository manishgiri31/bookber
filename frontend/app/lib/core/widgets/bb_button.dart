import 'package:flutter/material.dart';

import '../design/bb_colors.dart';
import '../design/bb_tokens.dart';
import '../design/bb_typography.dart';

enum BBButtonVariant { primary, secondary, ghost, destructive }

class BBButton extends StatelessWidget {
  const BBButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BBButtonVariant.primary,
    this.loading = false,
    this.disabled = false,
    this.icon,
    this.iconAfter = false,
    this.small = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final BBButtonVariant variant;
  final bool loading;
  final bool disabled;
  final IconData? icon;
  final bool iconAfter;
  final bool small;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isDisabled = disabled || loading;
    final height = small ? 40.0 : 52.0;
    final fontSize = small ? 13.0 : 15.0;

    Color bg;
    Color fg;
    BorderSide? side;

    switch (variant) {
      case BBButtonVariant.primary:
        bg = isDisabled ? BBColors.amber.withValues(alpha: 0.4) : BBColors.amber;
        fg = isDisabled
            ? colors.accentForeground.withValues(alpha: 0.5)
            : colors.accentForeground;
        side = null;
      case BBButtonVariant.secondary:
        bg = colors.surfaceVariant;
        fg = isDisabled ? colors.textTertiary : colors.text;
        side = BorderSide(color: colors.border);
      case BBButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDisabled ? colors.textTertiary : colors.text;
        side = BorderSide(color: colors.border);
      case BBButtonVariant.destructive:
        bg = isDisabled
            ? BBColors.error.withValues(alpha: 0.3)
            : BBColors.error.withValues(alpha: 0.15);
        fg = isDisabled ? BBColors.error.withValues(alpha: 0.4) : BBColors.error;
        side = BorderSide(
          color: isDisabled
              ? BBColors.error.withValues(alpha: 0.2)
              : BBColors.error.withValues(alpha: 0.4),
        );
    }

    Widget child;
    if (loading) {
      child = SizedBox(
        width: small ? 16 : 20,
        height: small ? 16 : 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      final labelWidget = Text(
        label,
        style: BBTypography.textTheme.labelLarge?.copyWith(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      );

      if (icon != null) {
        final iconWidget = Icon(icon, size: small ? 16 : 18, color: fg);
        child = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconAfter
              ? [labelWidget, const SizedBox(width: 8), iconWidget]
              : [iconWidget, const SizedBox(width: 8), labelWidget],
        );
      } else {
        child = labelWidget;
      }
    }

    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(BBRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: side != null
                  ? Border.all(color: side.color, width: side.width)
                  : null,
              borderRadius: BorderRadius.circular(BBRadius.md),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: small ? BBSpacing.md : BBSpacing.lg,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
