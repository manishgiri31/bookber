import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/app_lock_provider.dart';
import '../data/auth_provider.dart';
import '../domain/auth_models.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _routePastLock(UserProfile user) {
    // Same source of truth the router's redirect consults, so the two never
    // disagree about whether the app should be locked.
    if (ref.read(biometricEnabledProvider)) {
      context.go('/lock');
      return;
    }

    ref.read(appLockProvider.notifier).unlock();
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
    ref.listen<AuthState>(authProvider, (_, next) {
      if (!mounted) return;
      switch (next) {
        case AuthAuthenticated(:final user):
          _routePastLock(user);
        case AuthUnauthenticated():
          context.go('/login');
        case _:
          break;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Opacity(
          opacity: _fadeIn.value,
          child: Transform.scale(
            scale: _scaleIn.value,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(BBRadius.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: BBColors.amber.withValues(alpha: 0.4),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(BBRadius.xxl),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: BBSpacing.xl),
                  const Text(
                    'BookBer',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: BBSpacing.sm),
                  Text(
                    'Premium Barber Booking',
                    style: BBTypography.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: BBSpacing.xxxl),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BBColors.amber.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
