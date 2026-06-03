import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BookerButtonVariant { primary, outlined, ghost, danger }

class BookerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final Widget? icon;
  final BookerButtonVariant variant;

  const BookerButton({
    Key? key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.icon,
    this.variant = BookerButtonVariant.primary,
  }) : super(key: key);

  Color _bgColor(BuildContext context) {
    switch (variant) {
      case BookerButtonVariant.primary:
        return AppColors.accentPrimary;
      case BookerButtonVariant.outlined:
      case BookerButtonVariant.ghost:
        return Colors.transparent;
      case BookerButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color _textColor(BuildContext context) {
    switch (variant) {
      case BookerButtonVariant.primary:
      case BookerButtonVariant.danger:
        return AppColors.textPrimary;
      case BookerButtonVariant.outlined:
      case BookerButtonVariant.ghost:
        return AppColors.accentPrimary;
    }
  }

  BorderSide? _border(BuildContext context) {
    switch (variant) {
      case BookerButtonVariant.outlined:
        return BorderSide(color: Theme.of(context).colorScheme.primary);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled || isLoading;
    final child = isLoading
        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _textColor(context)))
        : Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(label, style: TextStyle(color: _textColor(context), fontWeight: FontWeight.w600)),
          ]);

    final button = ConstrainedBox(
      constraints: BoxConstraints(minHeight: 56, minWidth: width ?? 0),
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _bgColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: _border(context) ?? BorderSide.none),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: child,
      ),
    );

    if (variant == BookerButtonVariant.ghost) {
      return TextButton(onPressed: disabled ? null : onTap, child: child);
    }

    return button;
  }
}
