import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/design_system.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    Future<void>.delayed(
      const Duration(milliseconds: 2200),
      _handleNavigation,
    );
  }

  Future<void> _handleNavigation() async {
    final authState = await ref.read(authStateProvider.future);
    await ref.read(onboardingBootstrapProvider.future);

    if (!mounted) return;

    if (authState is AuthAuthenticated) {
      if (authState.user.role == UserRole.barber.value) {
        context.go('/barber');
        return;
      }

      context.go('/home');
      return;
    }

    context.go('/onboarding');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: BookBerPalette.primaryAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'B',
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'BookBer',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 28,
                  color: BookBerPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Premium Grooming, On Demand',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BookBerPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
