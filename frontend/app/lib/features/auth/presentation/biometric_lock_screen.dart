import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/app_lock_provider.dart';
import '../../../core/widgets/bb_button.dart';
import '../data/auth_provider.dart';

/// Shown after a biometric-locked session is restored. Blocks navigation
/// into the app until the OS biometric/PIN prompt succeeds.
class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_authenticate);
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final ok = await ref
        .read(biometricServiceProvider)
        .authenticate('Unlock BookBer to continue');

    if (!mounted) return;
    setState(() => _authenticating = false);

    if (ok) {
      ref.read(appLockProvider.notifier).unlock();
      _goToDestination();
    } else {
      setState(() => _error = 'Authentication failed. Try again.');
    }
  }

  void _goToDestination() {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) {
      context.go('/login');
      return;
    }
    final user = auth.user;
    if (user.isBarber || user.isOwner) {
      context.go('/barber');
    } else if (user.isReception) {
      context.go('/barber/reception');
    } else if (user.isAdmin) {
      context.go('/admin');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(BBSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.fingerprint,
                    size: 40,
                    color: context.bbColors.accent,
                  ),
                ),
                const SizedBox(height: BBSpacing.xl),
                Text(
                  'BookBer is locked',
                  style: BBTypography.textTheme.headlineSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BBSpacing.sm),
                Text(
                  'Use biometrics to unlock',
                  style: BBTypography.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: BBSpacing.md),
                  Text(
                    _error!,
                    style: BBTypography.textTheme.bodySmall?.copyWith(
                      color: BBColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: BBSpacing.xxxl),
                BBButton(
                  label: 'Unlock',
                  icon: AppIcons.fingerprint,
                  loading: _authenticating,
                  onPressed: _authenticate,
                ),
                const SizedBox(height: BBSpacing.md),
                TextButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  child: Text(
                    'Sign in with a different account',
                    style: BBTypography.textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
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
