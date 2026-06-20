import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/bb_colors.dart';
import '../design/bb_tokens.dart';
import '../design/bb_typography.dart';

class BBTextField extends StatefulWidget {
  const BBTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixWidget,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
  });

  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool autofocus;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final bool enabled;

  @override
  State<BBTextField> createState() => _BBTextFieldState();
}

class _BBTextFieldState extends State<BBTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: BBTypography.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          maxLines: _obscured ? 1 : widget.maxLines,
          minLines: widget.minLines,
          enabled: widget.enabled,
          style: BBTypography.textTheme.bodyLarge?.copyWith(
            color: colors.text,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: BBTypography.textTheme.bodyLarge?.copyWith(
              color: colors.textTertiary,
            ),
            filled: true,
            fillColor: widget.enabled ? colors.surfaceVariant : colors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BBRadius.md),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BBRadius.md),
              borderSide: BorderSide(
                color: hasError ? BBColors.error : colors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BBRadius.md),
              borderSide: BorderSide(
                color: hasError ? BBColors.error : BBColors.amber,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BBRadius.md),
              borderSide: const BorderSide(color: BBColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BBRadius.md),
              borderSide: const BorderSide(color: BBColors.error, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.base,
              vertical: BBSpacing.md,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: colors.textSecondary,
                  )
                : null,
            suffixIcon: _buildSuffix(colors),
            error: hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: BBSpacing.xs),
                    child: Text(
                      widget.errorText!,
                      style: BBTypography.textTheme.bodySmall?.copyWith(
                        color: BBColors.error,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        if (widget.helperText != null && !hasError) ...[
          const SizedBox(height: BBSpacing.xs),
          Text(
            widget.helperText!,
            style: BBTypography.textTheme.bodySmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffix(BBColorScheme colors) {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: colors.textSecondary,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }
    return widget.suffixWidget;
  }
}
