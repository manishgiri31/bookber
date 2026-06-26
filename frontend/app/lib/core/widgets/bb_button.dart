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
    final height = small ? 44.0 : 56.0;
    final fontSize = small ? 13.0 : 15.0;

    Color bg;
    Color fg;
    List<BoxShadow>? shadows;

    switch (variant) {
      case BBButtonVariant.primary:
        bg = isDisabled ? colors.accent.withValues(alpha: 0.4) : colors.accent;
        fg = isDisabled
            ? colors.accentForeground.withValues(alpha: 0.5)
            : colors.accentForeground;
        shadows = isDisabled
            ? null
            : [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ];
      case BBButtonVariant.secondary:
        bg = colors.surfaceVariant;
        fg = isDisabled ? colors.textTertiary : colors.text;
        shadows = null;
      case BBButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDisabled ? colors.textTertiary : colors.text;
        shadows = null;
      case BBButtonVariant.destructive:
        bg = isDisabled
            ? BBColors.error.withValues(alpha: 0.1)
            : BBColors.error.withValues(alpha: 0.12);
        fg = isDisabled ? BBColors.error.withValues(alpha: 0.4) : BBColors.error;
        shadows = null;
    }

    Widget child;
    if (loading) {
      child = SizedBox(
        width: small ? 18 : 22,
        height: small ? 18 : 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
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
          letterSpacing: 0.1,
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BBRadius.full),
          boxShadow: shadows,
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(BBRadius.full),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            splashColor: fg.withValues(alpha: 0.08),
            highlightColor: fg.withValues(alpha: 0.04),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: small ? BBSpacing.md : BBSpacing.xl,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
