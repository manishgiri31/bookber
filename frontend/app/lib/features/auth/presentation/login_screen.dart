import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/auth_layout.dart';
import '../../../core/widgets/auth_input_field.dart';
import '../../../core/widgets/role_selector.dart';
import '../../../core/utils/snackbar.dart';
import '../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthError && mounted) {
        BookerSnackbar.error(context, next.message);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
    } else if (!email.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email');
    } else {
      setState(() => _emailError = null);
    }
  }

  void _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
    } else {
      setState(() => _passwordError = null);
    }
  }

  Future<void> _handleLogin() async {
    _validateEmail();
    _validatePassword();

    if (_emailError != null || _passwordError != null) return;

    await ref.read(authControllerProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
          role: _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthLayout(
      title: 'Welcome back',
      subtitle: 'Sign in to your account',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Role Selector
            RoleSelector(
              selectedRole: _selectedRole,
              onChanged: (role) => setState(() => _selectedRole = role),
            ),
            const SizedBox(height: 24),

            // Email Field
            AuthInputField(
              label: 'Email',
              controller: _emailController,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _emailError,
              onChanged: (_) => setState(() => _emailError = null),
            ),
            const SizedBox(height: 16),

            // Password Field
            AuthInputField(
              label: 'Password',
              controller: _passwordController,
              prefixIcon: Icons.lock_outline,
              suffixIcon: _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              onSuffixIconPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              errorText: _passwordError,
              onChanged: (_) => setState(() => _passwordError = null),
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 8),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement forgot password
                },
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: BookBerPalette.primaryAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: authState.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          color: BookBerPalette.primaryAccent,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BookBerPalette.primaryAccent,
                        foregroundColor: BookBerPalette.bgPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 32),

            // Social Auth Divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0x0FFFFFFF),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or continue with',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: BookBerPalette.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0x0FFFFFFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Social Auth Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement Google auth
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 20),
                    label: Text(
                      'Google',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BookBerPalette.textPrimary,
                      side: const BorderSide(color: Color(0x0FFFFFFF), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement Apple auth
                    },
                    icon: const Icon(Icons.apple, size: 20),
                    label: Text(
                      'Apple',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BookBerPalette.textPrimary,
                      side: const BorderSide(color: Color(0x0FFFFFFF), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Register Link
            Center(
              child: GestureDetector(
                onTap: () => context.go('/register'),
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: BookBerPalette.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Register',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BookBerPalette.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
