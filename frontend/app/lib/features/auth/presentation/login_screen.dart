import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens.dart';
import '../../../core/components/bb_button.dart';
import '../../../core/components/bb_input.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/snackbar.dart';
import '../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _enterCtrl = AnimationController(vsync: this, duration: BBMotion.xslow);
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: BBMotion.enter);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: BBMotion.smooth));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final v = _emailCtrl.text.trim();
    setState(() {
      _emailError = v.isEmpty
          ? 'Email is required'
          : !v.contains('@')
              ? 'Enter a valid email address'
              : null;
    });
  }

  void _validatePassword() {
    final v = _passwordCtrl.text;
    setState(() {
      _passwordError = v.isEmpty
          ? 'Password is required'
          : v.length < 6
              ? 'At least 6 characters required'
              : null;
    });
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your email address and we\'ll send you a reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset link sent! Check your inbox.'),
                ),
              );
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }

  Future<void> _handleLogin() async {
    _validateEmail();
    _validatePassword();
    if (_emailError != null || _passwordError != null) return;
    await ref.read(authControllerProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is AuthError && mounted) {
        BookerSnackbar.error(context, next.message);
      }
    });

    return Scaffold(
      backgroundColor: BBColors.bgCanvas,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.px24,
                vertical: BBSpacing.px16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ───────────────────────────────────────
                  const SizedBox(height: BBSpacing.px24),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: BBColors.brandPrimary,
                            borderRadius: BBRadius.md,
                            boxShadow: BBElevation.brandGlow(
                              BBColors.brandPrimary,
                              intensity: 0.25,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'B',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: BBColorPrimitives.neutral50,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: BBSpacing.px12),
                        const Text('BookBer', style: BBTypography.displayS),
                      ],
                    ),
                  ),

                  const SizedBox(height: BBSpacing.px40),

                  // ── Headline ─────────────────────────────────
                  const Text('Welcome back', style: BBTypography.displayM),
                  const SizedBox(height: BBSpacing.px6),
                  const Text('Sign in to continue', style: BBTypography.bodyM),

                  const SizedBox(height: BBSpacing.px32),

                  // ── Role selector ────────────────────────────
                  BBSegmentedControl<UserRole>(
                    selected: _role,
                    onChanged: (r) => setState(() => _role = r),
                    options: const [
                      BBSegmentOption(
                        label: 'Customer',
                        value: UserRole.customer,
                        icon: Icons.person_outline,
                      ),
                      BBSegmentOption(
                        label: 'Barber',
                        value: UserRole.barber,
                        icon: Icons.content_cut,
                      ),
                    ],
                  ),

                  const SizedBox(height: BBSpacing.px28),

                  // ── Email ────────────────────────────────────
                  BBTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    onChanged: (_) => setState(() => _emailError = null),
                  ),

                  const SizedBox(height: BBSpacing.px20),

                  // ── Password ─────────────────────────────────
                  BBTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordCtrl,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    errorText: _passwordError,
                    onChanged: (_) => setState(() => _passwordError = null),
                    onSubmitted: (_) => _handleLogin(),
                  ),

                  const SizedBox(height: BBSpacing.px12),

                  // ── Forgot password ──────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _showForgotPasswordDialog(context),
                      child: Text(
                        'Forgot password?',
                        style: BBTypography.labelM.copyWith(
                          color: BBColors.brandPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: BBSpacing.px32),

                  // ── Sign in button ───────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: BBButton(
                      label: 'Sign In',
                      onPressed: isLoading ? null : _handleLogin,
                      isLoading: isLoading,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ),

                  const SizedBox(height: BBSpacing.px32),

                  // ── Divider ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: BBColors.borderSubtle,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BBSpacing.px16,
                        ),
                        child: Text(
                          'or',
                          style: BBTypography.labelS,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: BBColors.borderSubtle,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: BBSpacing.px28),

                  // ── Social auth ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: 'Google',
                          icon: Icons.g_mobiledata_rounded,
                          onTap: () => _showComingSoon(context, 'Google Sign-In'),
                        ),
                      ),
                      const SizedBox(width: BBSpacing.px12),
                      Expanded(
                        child: _SocialButton(
                          label: 'Apple',
                          icon: Icons.apple,
                          onTap: () => _showComingSoon(context, 'Apple Sign-In'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: BBSpacing.px40),

                  // ── Register link ────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/register'),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: BBTypography.bodyM,
                          children: [
                            TextSpan(
                              text: 'Create one',
                              style: BBTypography.labelL.copyWith(
                                color: BBColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: BBSpacing.px24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SOCIAL BUTTON
// ─────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: BBTouchTarget.button,
        decoration: BoxDecoration(
          color: BBColors.bgSurface,
          borderRadius: BBRadius.pill,
          border: Border.all(color: BBColors.borderDefault, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: BBIconSize.lg, color: BBColors.textPrimary),
            const SizedBox(width: BBSpacing.px8),
            Text(label, style: BBTypography.labelL),
          ],
        ),
      ),
    );
  }
}
