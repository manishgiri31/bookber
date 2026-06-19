import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.dart';

class AuthInputField extends StatefulWidget {
  const AuthInputField({
    super.key,
    required this.label,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? maxLength;

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.maxLines == 1 ? 56 : null,
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BBRadius.md,
            border: Border.all(
              color: _isFocused
                  ? BBColors.brandPrimary
                  : hasError
                      ? BBColors.error
                      : colors.border,
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: BBColors.brandPrimaryGlow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: FocusScope(
            onFocusChange: (hasFocus) =>
                setState(() => _isFocused = hasFocus),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              onSubmitted: widget.onSubmitted,
              style: BBTypography.bodyL.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: BBTypography.bodyM.copyWith(
                  color: _isFocused ? BBColors.brandPrimary : colors.textSecondary,
                ),
                floatingLabelStyle: BBTypography.labelM.copyWith(
                  color: _isFocused ? BBColors.brandPrimary : colors.textSecondary,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon,
                        color: BBColors.brandPrimary, size: BBIconSize.sm)
                    : null,
                suffixIcon: widget.suffixIcon != null
                    ? IconButton(
                        icon: Icon(widget.suffixIcon,
                            color: colors.textSecondary, size: BBIconSize.sm),
                        onPressed: widget.onSuffixIconPressed,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: BBSpacing.px16, vertical: BBSpacing.px16),
                counterText: '',
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: BBSpacing.px6),
          Padding(
            padding: const EdgeInsets.only(left: BBSpacing.px4),
            child: Text(
              widget.errorText!,
              style: BBTypography.labelS.copyWith(color: BBColors.error),
            ),
          ),
        ],
      ],
    );
  }
}
