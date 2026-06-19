import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/onboarding_provider.dart';
import '../auth/domain/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: BBMotion.spring),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.6)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: BBMotion.enter),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: BBMotion.smooth),
    );

    _logoCtrl.forward().then((_) => _textCtrl.forward());

    Future.delayed(const Duration(milliseconds: 2400), _handleNavigation);
  }

  Future<void> _handleNavigation() async {
    // Run auth check and onboarding lookup concurrently.
    await Future.wait([
      ref.read(authControllerProvider.notifier).checkAuth(navigate: false),
      ref.read(onboardingBootstrapProvider.future),
    ]);

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    final onboardingDone = ref.read(onboardingCompletedProvider);

    if (authState is AuthAuthenticated) {
      context.go(authState.user.role == UserRole.barber.value ? '/barber' : '/home');
      return;
    }

    context.go(onboardingDone ? '/login' : '/onboarding');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BBColors.bgCanvas,
      body: Stack(
        children: [
          // Subtle radial glow behind logo
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _logoOpacity,
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value * 0.4,
                child: Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          BBColors.brandPrimary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mark
                AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (_, child) => Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: BBColors.brandPrimary,
                      borderRadius: BBRadius.xl,
                      boxShadow: BBElevation.brandGlow(BBColors.brandPrimary, intensity: 0.35),
                    ),
                    child: const Center(
                      child: Text(
                        'B',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: BBColorPrimitives.neutral50,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: BBSpacing.px24),

                // Wordmark + tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        const Text(
                          'BookBer',
                          style: BBTypography.displayL,
                        ),
                        const SizedBox(height: BBSpacing.px6),
                        Text(
                          'Premium Grooming, On Demand',
                          style: BBTypography.bodyM.copyWith(
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom version tag
          Positioned(
            bottom: BBSpacing.px40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: const Text(
                'v1.0',
                textAlign: TextAlign.center,
                style: BBTypography.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
