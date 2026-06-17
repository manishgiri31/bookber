import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';

// ─────────────────────────────────────────────────────────────
// BB TEXT FIELD — with focus animation + error states
// ─────────────────────────────────────────────────────────────

class BBTextField extends StatefulWidget {
  const BBTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofocus = false,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.initialValue,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final String? initialValue;

  @override
  State<BBTextField> createState() => _BBTextFieldState();
}

class _BBTextFieldState extends State<BBTextField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focus;
  late final AnimationController _borderCtrl;
  late final Animation<Color?> _borderColor;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _borderCtrl = AnimationController(vsync: this, duration: BBMotion.fast);
    _borderColor = ColorTween(
      begin: BBColors.borderDefault,
      end: BBColors.brandPrimary,
    ).animate(CurvedAnimation(parent: _borderCtrl, curve: BBMotion.smooth));

    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
      if (_focus.hasFocus) {
        _borderCtrl.forward();
      } else {
        _borderCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    _borderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: BBTypography.labelL.copyWith(
              color: hasError
                  ? BBColors.error
                  : _isFocused
                      ? BBColors.brandPrimary
                      : BBColors.textSecondary,
            ),
          ),
          const SizedBox(height: BBSpacing.px8),
        ],
        AnimatedBuilder(
          animation: _borderColor,
          builder: (context, child) {
            final borderColor = hasError
                ? BBColors.error
                : _borderColor.value ?? BBColors.borderDefault;

            return Container(
              decoration: BoxDecoration(
                color: BBColors.bgSurface,
                borderRadius: BBRadius.md,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: child,
            );
          },
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            enabled: widget.enabled,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            style: BBTypography.bodyL.copyWith(color: BBColors.textPrimary),
            cursorColor: BBColors.brandPrimary,
            cursorWidth: 2,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: BBTypography.bodyL.copyWith(color: BBColors.textDisabled),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: BBIconSize.md,
                      color: _isFocused ? BBColors.brandPrimary : BBColors.textSecondary,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixTap,
                      child: Icon(
                        widget.suffixIcon,
                        size: BBIconSize.md,
                        color: BBColors.textSecondary,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.px16,
                vertical: BBSpacing.px16,
              ),
              counterText: '',
              isDense: false,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: BBSpacing.px6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: BBIconSize.xs, color: BBColors.error),
              const SizedBox(width: BBSpacing.px4),
              Text(
                widget.errorText!,
                style: BBTypography.labelS.copyWith(color: BBColors.error),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: BBSpacing.px6),
          Text(
            widget.helperText!,
            style: BBTypography.caption,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BB SEARCH FIELD — tappable search bar
// ─────────────────────────────────────────────────────────────

class BBSearchField extends StatelessWidget {
  const BBSearchField({
    super.key,
    this.hint = 'Search...',
    this.onTap,
    this.controller,
    this.onChanged,
    this.autofocus = false,
    this.onSubmitted,
  });

  final String hint;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    // If onTap is provided, this is a tappable search trigger (not actually editable)
    if (onTap != null && controller == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: BBColors.bgSurface,
            borderRadius: BBRadius.md,
            border: Border.all(color: BBColors.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: BBSpacing.px14),
              const Icon(Icons.search, size: BBIconSize.md, color: BBColors.brandPrimary),
              const SizedBox(width: BBSpacing.px12),
              Text(hint, style: BBTypography.bodyM),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.md,
        border: Border.all(color: BBColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: BBSpacing.px14),
          const Icon(Icons.search, size: BBIconSize.md, color: BBColors.brandPrimary),
          const SizedBox(width: BBSpacing.px12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              autofocus: autofocus,
              style: BBTypography.bodyL.copyWith(color: BBColors.textPrimary),
              cursorColor: BBColors.brandPrimary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: BBTypography.bodyL.copyWith(color: BBColors.textDisabled),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BB SEGMENTED CONTROL (role selector, tab picker)
// ─────────────────────────────────────────────────────────────

class BBSegmentedControl<T> extends StatelessWidget {
  const BBSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.fullWidth = true,
  });

  final List<BBSegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.md,
        border: Border.all(color: BBColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.value == selected;
          return Expanded(
            flex: fullWidth ? 1 : 0,
            child: GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: BBMotion.fast,
                curve: BBMotion.smooth,
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px12),
                decoration: BoxDecoration(
                  color: isSelected ? BBColors.brandPrimary : Colors.transparent,
                  borderRadius: BBRadius.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (opt.icon != null) ...[
                      Icon(
                        opt.icon,
                        size: BBIconSize.sm,
                        color: isSelected ? BBColorPrimitives.neutral50 : BBColors.textSecondary,
                      ),
                      const SizedBox(width: BBSpacing.px6),
                    ],
                    Text(
                      opt.label,
                      style: BBTypography.labelM.copyWith(
                        color: isSelected ? BBColorPrimitives.neutral50 : BBColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BBSegmentOption<T> {
  const BBSegmentOption({required this.label, required this.value, this.icon});
  final String label;
  final T value;
  final IconData? icon;
}
