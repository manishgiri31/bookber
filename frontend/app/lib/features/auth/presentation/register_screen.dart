import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_text_field.dart';
import '../data/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _selectedRole = 'customer';
  bool _submitting = false;

  String? _nameError;
  String? _emailError;
  String? _passError;
  String? _confirmError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passError = null;
      _confirmError = null;
    });
    bool ok = true;
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _nameError = 'Enter your full name');
      ok = false;
    }
    if (!_emailCtrl.text.contains('@') || !_emailCtrl.text.contains('.')) {
      setState(() => _emailError = 'Enter a valid email');
      ok = false;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _passError = 'Minimum 6 characters');
      ok = false;
    }
    if (_confirmCtrl.text != _passCtrl.text) {
      setState(() => _confirmError = 'Passwords do not match');
      ok = false;
    }
    return ok;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);
    final ok = await ref.read(authProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
          role: _selectedRole,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      final err = ref.read(authProvider);
      showBBSnackbar(
        context,
        message: err is AuthError ? err.message : 'Registration failed.',
        isError: true,
      );
      ref.read(authProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpacing.pageHorizontal,
            vertical: BBSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join BookBer',
                style: BBTypography.textTheme.displaySmall?.copyWith(
                  color: colors.text,
                ),
              ),
              const SizedBox(height: BBSpacing.sm),
              Text(
                'Create your account to get started',
                style: BBTypography.textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: BBSpacing.xl),

              // Role selector
              Text(
                'I am a',
                style: BBTypography.textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: BBSpacing.sm),
              Row(
                children: [
                  _RoleTile(
                    label: 'Customer',
                    icon: Icons.person_outline_rounded,
                    selected: _selectedRole == 'customer',
                    onTap: () => setState(() => _selectedRole = 'customer'),
                  ),
                  const SizedBox(width: BBSpacing.sm),
                  _RoleTile(
                    label: 'Barber',
                    icon: Icons.content_cut_rounded,
                    selected: _selectedRole == 'barber',
                    onTap: () => setState(() => _selectedRole = 'barber'),
                  ),
                ],
              ),
              const SizedBox(height: BBSpacing.xl),

              BBTextField(
                label: 'Full Name',
                hint: 'John Doe',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                errorText: _nameError,
              ),
              const SizedBox(height: BBSpacing.base),
              BBTextField(
                label: 'Email',
                hint: 'you@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                textInputAction: TextInputAction.next,
                errorText: _emailError,
              ),
              const SizedBox(height: BBSpacing.base),
              BBTextField(
                label: 'Phone (optional)',
                hint: '+91 98765 43210',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: BBSpacing.base),
              BBTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passCtrl,
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
                textInputAction: TextInputAction.next,
                errorText: _passError,
              ),
              const SizedBox(height: BBSpacing.base),
              BBTextField(
                label: 'Confirm Password',
                hint: '••••••••',
                controller: _confirmCtrl,
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
                textInputAction: TextInputAction.done,
                errorText: _confirmError,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: BBSpacing.xl),
              BBButton(
                label: 'Create Account',
                onPressed: _submit,
                loading: _submitting,
              ),
              const SizedBox(height: BBSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Already have an account? Sign in',
                    style: BBTypography.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: BBSpacing.base,
            horizontal: BBSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? BBColors.amber.withValues(alpha: 0.12) : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(BBRadius.md),
            border: Border.all(
              color: selected ? BBColors.amber : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? BBColors.amber : colors.textSecondary,
              ),
              const SizedBox(width: BBSpacing.sm),
              Text(
                label,
                style: BBTypography.textTheme.labelLarge?.copyWith(
                  color: selected ? BBColors.amber : colors.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
