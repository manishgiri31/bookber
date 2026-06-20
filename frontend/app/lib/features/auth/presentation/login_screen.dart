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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _emailError;
  String? _passError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = null;
      _passError = null;
    });
    bool valid = true;
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      setState(() => _emailError = 'Enter a valid email address');
      valid = false;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _passError = 'Password must be at least 6 characters');
      valid = false;
    }
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);
    final ok = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      final err = ref.read(authProvider);
      showBBSnackbar(
        context,
        message: err is AuthError ? err.message : 'Login failed.',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpacing.pageHorizontal,
            vertical: BBSpacing.pageVertical,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: BBSpacing.xl),
                // Logo
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: BBColors.amber,
                    borderRadius: BorderRadius.circular(BBRadius.md),
                  ),
                  child: const Center(
                    child: Text(
                      'B',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF09090B),
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: BBSpacing.xl),
                Text(
                  'Welcome back',
                  style: BBTypography.textTheme.displaySmall?.copyWith(
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: BBSpacing.sm),
                Text(
                  'Sign in to your BookBer account',
                  style: BBTypography.textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: BBSpacing.xxl),
                BBTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _emailError,
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                const SizedBox(height: BBSpacing.base),
                BBTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  errorText: _passError,
                  prefixIcon: Icons.lock_outline_rounded,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: BBSpacing.lg),
                BBButton(
                  label: 'Sign In',
                  onPressed: _submit,
                  loading: _submitting,
                ),
                const SizedBox(height: BBSpacing.base),
                _Divider(),
                const SizedBox(height: BBSpacing.base),
                OutlinedButton(
                  onPressed: () => context.push('/register'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BBRadius.md),
                    ),
                  ),
                  child: Text(
                    'Create an account',
                    style: BBTypography.textTheme.labelLarge?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Row(
      children: [
        Expanded(child: Divider(color: colors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BBSpacing.base),
          child: Text(
            'or',
            style: BBTypography.textTheme.bodySmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.border, height: 1)),
      ],
    );
  }
}
