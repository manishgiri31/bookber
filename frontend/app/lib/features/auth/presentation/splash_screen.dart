import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../data/auth_provider.dart';

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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (!mounted) return;
      switch (next) {
        case AuthAuthenticated(:final user):
          if (user.isBarber) {
            context.go('/barber');
          } else if (user.isAdmin) {
            context.go('/admin');
          } else {
            context.go('/home');
          }
        case AuthUnauthenticated():
          context.go('/login');
        case _:
          break;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
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
                  _LogoMark(),
                  const SizedBox(height: BBSpacing.lg),
                  const Text(
                    'BookBer',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: BBSpacing.sm),
                  Text(
                    'Premium Barber Booking',
                    style: BBTypography.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: BBSpacing.xxxl),
                  SizedBox(
                    width: 24,
                    height: 24,
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

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: BBColors.amber,
        borderRadius: BorderRadius.circular(BBRadius.xl),
      ),
      child: const Center(
        child: Text(
          'B',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Color(0xFF09090B),
            height: 1,
          ),
        ),
      ),
    );
  }
}
