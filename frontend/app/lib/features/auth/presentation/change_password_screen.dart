import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/api_result.dart';
import '../data/auth_repository.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Live password requirement checks
  bool get _hasMinLength => _newPwCtrl.text.length >= 8;
  bool get _hasUppercase => _newPwCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _newPwCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _newPwCtrl.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _allMet => _hasMinLength && _hasUppercase && _hasNumber && _hasSpecial;

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_allMet) {
      setState(() => _errorMessage = 'New password does not meet all requirements.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authRepositoryProvider).changePassword(
      currentPassword: _currentPwCtrl.text,
      newPassword: _newPwCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case ApiSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
        Navigator.of(context).pop();
      case ApiError(:final message):
        setState(() => _errorMessage = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgCanvas,
        title: Text(
          'Change Password',
          style: BBTypography.headingL.copyWith(color: colors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: BBIconSize.md, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: BBSpacing.pagePadding.copyWith(
              top: BBSpacing.px24, bottom: BBSpacing.px32),
          children: [
            // Current password
            _PasswordField(
              controller: _currentPwCtrl,
              label: 'Current Password',
              show: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your current password' : null,
            ),
            const SizedBox(height: BBSpacing.px16),

            // New password
            _PasswordField(
              controller: _newPwCtrl,
              label: 'New Password',
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a new password';
                if (!_allMet) return 'Password does not meet all requirements';
                return null;
              },
            ),
            const SizedBox(height: BBSpacing.px12),

            // Requirements list
            _PasswordRequirements(
              hasMinLength: _hasMinLength,
              hasUppercase: _hasUppercase,
              hasNumber: _hasNumber,
              hasSpecial: _hasSpecial,
              colors: colors,
            ),
            const SizedBox(height: BBSpacing.px16),

            // Confirm password
            _PasswordField(
              controller: _confirmPwCtrl,
              label: 'Confirm New Password',
              show: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your new password';
                if (v != _newPwCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: BBSpacing.px12),
              Text(
                _errorMessage!,
                style: BBTypography.bodyS.copyWith(color: BBColors.error),
              ),
            ],

            const SizedBox(height: BBSpacing.px32),

            SizedBox(
              width: double.infinity,
              height: BBTouchTarget.button,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Password text field ────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      onChanged: onChanged,
      validator: validator,
      style: BBTypography.bodyL.copyWith(color: context.bbColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: BBIconSize.md,
            color: context.bbColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ── Requirements widget ────────────────────────────────────────

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasNumber,
    required this.hasSpecial,
    required this.colors,
  });

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasNumber;
  final bool hasSpecial;
  final BBColorTheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: BBSpacing.cardPaddingSmall,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BBRadius.md,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements',
            style: BBTypography.labelS.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BBSpacing.px8),
          _Req(met: hasMinLength, text: 'At least 8 characters'),
          _Req(met: hasUppercase, text: 'At least one uppercase letter (A–Z)'),
          _Req(met: hasNumber, text: 'At least one number (0–9)'),
          _Req(
              met: hasSpecial,
              text: r'At least one special character (!@#$%...)'),
        ],
      ),
    );
  }
}

class _Req extends StatelessWidget {
  const _Req({required this.met, required this.text});
  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BBSpacing.px2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: met ? BBColors.success : colors.textDisabled,
          ),
          const SizedBox(width: BBSpacing.px8),
          Text(
            text,
            style: BBTypography.bodyS.copyWith(
                color: met ? BBColors.success : colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
