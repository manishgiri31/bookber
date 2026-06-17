import 'package:flutter/material.dart';
import '../design/tokens.dart';

// ─────────────────────────────────────────────────────────────
// BB BUTTON — primary, secondary, ghost, danger, icon variants
// ─────────────────────────────────────────────────────────────

enum _BBButtonVariant { primary, secondary, ghost, danger, brand }
enum BBButtonSize { large, medium, small }

class BBButton extends StatelessWidget {
  const BBButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BBButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.trailing,
  }) : _variant = _BBButtonVariant.primary;

  const BBButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BBButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.trailing,
  }) : _variant = _BBButtonVariant.secondary;

  const BBButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BBButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.trailing,
  }) : _variant = _BBButtonVariant.ghost;

  const BBButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BBButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.trailing,
  }) : _variant = _BBButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final BBButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final Widget? trailing;
  final _BBButtonVariant _variant;

  double get _height {
    switch (size) {
      case BBButtonSize.large: return BBTouchTarget.button;
      case BBButtonSize.medium: return BBTouchTarget.buttonSmall;
      case BBButtonSize.small: return 36.0;
    }
  }

  TextStyle get _textStyle {
    switch (size) {
      case BBButtonSize.large: return BBTypography.button;
      case BBButtonSize.medium: return BBTypography.button;
      case BBButtonSize.small: return BBTypography.buttonS;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case BBButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: BBSpacing.px24);
      case BBButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: BBSpacing.px20);
      case BBButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: BBSpacing.px14);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_variant) {
      case _BBButtonVariant.primary:
        return _PrimaryButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          height: _height,
          textStyle: _textStyle,
          padding: _padding,
          isLoading: isLoading,
          icon: icon,
          trailing: trailing,
        );
      case _BBButtonVariant.secondary:
        return _SecondaryButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          height: _height,
          textStyle: _textStyle,
          padding: _padding,
          isLoading: isLoading,
          icon: icon,
        );
      case _BBButtonVariant.ghost:
        return _GhostButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          height: _height,
          textStyle: _textStyle,
          padding: _padding,
          isLoading: isLoading,
          icon: icon,
        );
      case _BBButtonVariant.danger:
        return _DangerButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          height: _height,
          textStyle: _textStyle,
          padding: _padding,
          isLoading: isLoading,
          icon: icon,
        );
      case _BBButtonVariant.brand:
        return _PrimaryButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          height: _height,
          textStyle: _textStyle,
          padding: _padding,
          isLoading: isLoading,
          icon: icon,
          trailing: trailing,
        );
    }
  }
}

// ─── PRIMARY ───────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.height,
    required this.textStyle,
    required this.padding,
    required this.isLoading,
    this.icon,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final TextStyle textStyle;
  final EdgeInsets padding;
  final bool isLoading;
  final IconData? icon;
  final Widget? trailing;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: BBMotion.fast,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.onPressed != null
                ? BBColors.brandPrimary
                : BBColors.brandPrimary.withValues(alpha: 0.4),
            borderRadius: BBRadius.pill,
            boxShadow: widget.onPressed != null
                ? BBElevation.brandGlow(BBColors.brandPrimary)
                : BBElevation.none,
          ),
          child: Padding(
            padding: widget.padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        BBColorPrimitives.neutral50.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: BBSpacing.px8),
                ],
                if (!widget.isLoading && widget.icon != null) ...[
                  Icon(widget.icon, size: BBIconSize.md, color: BBColorPrimitives.neutral50),
                  const SizedBox(width: BBSpacing.px8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: widget.textStyle.copyWith(
                      color: BBColorPrimitives.neutral50,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: BBSpacing.px8),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SECONDARY ─────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.height,
    required this.textStyle,
    required this.padding,
    required this.isLoading,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final TextStyle textStyle;
  final EdgeInsets padding;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: padding,
          side: const BorderSide(color: BBColors.borderDefault, width: 1.0),
          shape: const RoundedRectangleBorder(borderRadius: BBRadius.pill),
          foregroundColor: BBColors.textPrimary,
        ),
        child: _ButtonContent(
          label: label,
          textStyle: textStyle,
          isLoading: isLoading,
          icon: icon,
          color: BBColors.textPrimary,
        ),
      ),
    );
  }
}

// ─── GHOST ─────────────────────────────────────────────────

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.onPressed,
    required this.height,
    required this.textStyle,
    required this.padding,
    required this.isLoading,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final TextStyle textStyle;
  final EdgeInsets padding;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: padding,
          shape: const RoundedRectangleBorder(borderRadius: BBRadius.pill),
          foregroundColor: BBColors.brandPrimary,
        ),
        child: _ButtonContent(
          label: label,
          textStyle: textStyle,
          isLoading: isLoading,
          icon: icon,
          color: BBColors.brandPrimary,
        ),
      ),
    );
  }
}

// ─── DANGER ────────────────────────────────────────────────

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.onPressed,
    required this.height,
    required this.textStyle,
    required this.padding,
    required this.isLoading,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final TextStyle textStyle;
  final EdgeInsets padding;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: padding,
          side: const BorderSide(color: BBColors.error, width: 1.0),
          shape: const RoundedRectangleBorder(borderRadius: BBRadius.pill),
          foregroundColor: BBColors.error,
        ),
        child: _ButtonContent(
          label: label,
          textStyle: textStyle,
          isLoading: isLoading,
          icon: icon,
          color: BBColors.error,
        ),
      ),
    );
  }
}

// ─── ICON BUTTON ───────────────────────────────────────────

class BBIconButton extends StatelessWidget {
  const BBIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44.0,
    this.iconSize = BBIconSize.md,
    this.color,
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? BBColors.bgSurface,
          borderRadius: BBRadius.md,
        ),
        child: Icon(icon, size: iconSize, color: color ?? BBColors.textPrimary),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

// ─── SHARED CONTENT ────────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.textStyle,
    required this.isLoading,
    required this.color,
    this.icon,
  });

  final String label;
  final TextStyle textStyle;
  final bool isLoading;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(width: BBSpacing.px8),
        ],
        if (!isLoading && icon != null) ...[
          Icon(icon, size: BBIconSize.sm, color: color),
          const SizedBox(width: BBSpacing.px8),
        ],
        Text(
          label,
          style: textStyle.copyWith(color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
