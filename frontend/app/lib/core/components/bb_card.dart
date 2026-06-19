import 'package:flutter/material.dart';
import '../design/tokens.dart';

// ─────────────────────────────────────────────────────────────
// BB SURFACE CARD
// ─────────────────────────────────────────────────────────────

class BBCard extends StatelessWidget {
  const BBCard({
    super.key,
    required this.child,
    this.padding = BBSpacing.cardPadding,
    this.color,
    this.borderRadius = BBRadius.card,
    this.shadow = BBElevation.low,
    this.border = true,
    this.onTap,
    this.onLongPress,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadow;
  final bool border;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? BBColors.bgSurface : BBColors.bgSurfaceLight);
    final borderColor = isDark ? BBColors.borderSubtle : BBColors.borderSubtleLight;

    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: borderRadius,
        boxShadow: shadow,
        border: border
            ? Border.all(color: borderColor, width: 1.0)
            : null,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: cardColor,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            splashColor: BBColors.brandPrimaryDim,
            highlightColor: Colors.transparent,
            borderRadius: borderRadius,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return card;
  }
}

// ─────────────────────────────────────────────────────────────
// BB ELEVATED CARD (modal-like, higher surface)
// ─────────────────────────────────────────────────────────────

class BBElevatedCard extends StatelessWidget {
  const BBElevatedCard({
    super.key,
    required this.child,
    this.padding = BBSpacing.cardPadding,
    this.color,
    this.shadow = BBElevation.medium,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BBCard(
      color: color ?? (isDark ? BBColors.bgElevated : BBColors.bgElevatedLight),
      padding: padding,
      shadow: shadow,
      border: false,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BB GRADIENT CARD (promo / featured)
// ─────────────────────────────────────────────────────────────

class BBGradientCard extends StatelessWidget {
  const BBGradientCard({
    super.key,
    required this.child,
    this.gradient = const LinearGradient(
      colors: [BBColors.brandPrimary, BBColorPrimitives.indigo200],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.padding = BBSpacing.cardPadding,
    this.borderRadius = BBRadius.card,
    this.onTap,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Ink(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BB SECTION HEADER
// ─────────────────────────────────────────────────────────────

class BBSectionHeader extends StatelessWidget {
  const BBSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: BBSpacing.px20,
      vertical: BBSpacing.px4,
    ),
  });

  final String title;
  final String? action;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(title, style: BBTypography.headingL),
          ),
          if (action != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                action!,
                style: BBTypography.labelL.copyWith(color: BBColors.brandPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BB DIVIDER
// ─────────────────────────────────────────────────────────────

class BBDivider extends StatelessWidget {
  const BBDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = 1.0,
  });

  final double indent;
  final double endIndent;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      color: isDark ? BBColors.borderSubtle : BBColors.borderSubtleLight,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      height: thickness,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BB EMPTY STATE
// ─────────────────────────────────────────────────────────────

class BBEmptyState extends StatelessWidget {
  const BBEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpacing.px40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: BBColors.brandPrimaryDim,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: BBColors.brandPrimary),
            ),
            const SizedBox(height: BBSpacing.px20),
            Text(
              title,
              style: BBTypography.headingL,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: BBSpacing.px8),
              Text(
                subtitle!,
                style: BBTypography.bodyM,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && onAction != null) ...[
              const SizedBox(height: BBSpacing.px24),
              TextButton(
                onPressed: onAction,
                child: Text(
                  action!,
                  style: BBTypography.labelL.copyWith(color: BBColors.brandPrimary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BB INFO ROW (key-value pair)
// ─────────────────────────────────────────────────────────────

class BBInfoRow extends StatelessWidget {
  const BBInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: BBIconSize.sm, color: BBColors.textSecondary),
          const SizedBox(width: BBSpacing.px8),
        ],
        Expanded(
          child: Text(label, style: BBTypography.bodyM),
        ),
        if (trailing != null)
          trailing!
        else
          Text(
            value,
            style: BBTypography.labelL.copyWith(
              color: valueColor ?? BBColors.textPrimary,
            ),
          ),
      ],
    );
  }
}
