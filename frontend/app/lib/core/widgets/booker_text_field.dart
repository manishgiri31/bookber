import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BookerTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixWidget;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextEditingController? controller;

  const BookerTextField({
    Key? key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixWidget,
    this.isPassword = false,
    this.validator,
    this.controller,
  }) : super(key: key);

  @override
  State<BookerTextField> createState() => _BookerTextFieldState();
}

class _BookerTextFieldState extends State<BookerTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Padding(padding: const EdgeInsets.only(left:12,right:8), child: widget.prefixIcon) : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.accentPrimary),
              )
            : widget.suffixWidget,
      ),
    );
  }
}
