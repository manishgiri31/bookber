import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/components/bb_button.dart';
import '../../core/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      icon: Icons.schedule_rounded,
      accentIcon: Icons.content_cut_rounded,
      badge: 'No more waiting',
      title: 'Skip the Queue',
      subtitle:
          'Book your barber in seconds. No calls, no hassle — just show up fresh.',
    ),
    _PageData(
      icon: Icons.chair_alt_rounded,
      accentIcon: null,
      badge: 'Your spot, guaranteed',
      title: 'Your Chair, Reserved',
      subtitle:
          'BookBer barbers hold dedicated chairs for app users. Guaranteed every time.',
    ),
    _PageData(
      icon: Icons.format_list_numbered_rounded,
      accentIcon: Icons.bolt_rounded,
      badge: 'Real-time updates',
      title: 'Live Queue Tracking',
      subtitle:
          'See your position live, get notified the moment your turn approaches.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_currentPage < _pages.length - 1) {
      await _pageController.nextPage(
        duration: BBMotion.slow,
        curve: BBMotion.smooth,
      );
      return;
    }
    await ref.read(markOnboardingCompleteProvider.future);
    if (mounted) context.go('/login');
  }

  void _handleSkip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: BBMotion.slow,
      curve: BBMotion.smooth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: BBColors.bgCanvas,
      body: Stack(
        children: [
          // ── Page content ──────────────────────────────
          PageView.builder(
            controller: _pageController,
            physics: const _SpringPagePhysics(),
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _OnboardingPage(
              key: ValueKey(i),
              page: _pages[i],
            ),
          ),

          // ── Skip button ───────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                duration: BBMotion.normal,
                opacity: isLast ? 0 : 1,
                child: IgnorePointer(
                  ignoring: isLast,
                  child: GestureDetector(
                    onTap: _handleSkip,
                    child: Container(
                      margin: const EdgeInsets.all(BBSpacing.px16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BBSpacing.px14,
                        vertical: BBSpacing.px8,
                      ),
                      decoration: BoxDecoration(
                        color: BBColors.bgSurface,
                        borderRadius: BBRadius.pill,
                        border: Border.all(
                          color: BBColors.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: const Text('Skip', style: BBTypography.labelM),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom: dots + CTA ────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                BBSpacing.px24,
                BBSpacing.px24,
                BBSpacing.px24,
                BBSpacing.px24 + bottomPadding,
              ),
              decoration: BoxDecoration(
                color: BBColors.bgCanvas,
                border: Border(
                  top: BorderSide(color: BBColors.borderSubtle, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DotIndicator(
                    count: _pages.length,
                    active: _currentPage,
                  ),
                  const SizedBox(height: BBSpacing.px24),
                  SizedBox(
                    width: double.infinity,
                    child: BBButton(
                      label: isLast ? 'Get Started' : 'Continue',
                      onPressed: _handleContinue,
                      icon: isLast ? Icons.arrow_forward_rounded : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE DATA
// ─────────────────────────────────────────────────────────────

class _PageData {
  const _PageData({
    required this.icon,
    required this.accentIcon,
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final IconData? accentIcon;
  final String badge;
  final String title;
  final String subtitle;
}

// ─────────────────────────────────────────────────────────────
// ONBOARDING PAGE
// ─────────────────────────────────────────────────────────────

class _OnboardingPage extends StatefulWidget {
  const _OnboardingPage({super.key, required this.page});
  final _PageData page;

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: BBMotion.slow)..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: BBMotion.enter);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: BBMotion.smooth),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BBSpacing.px32,
            BBSpacing.px80,
            BBSpacing.px32,
            176.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Illustration box ─────────────────────
              _IllustrationBox(
                icon: widget.page.icon,
                accentIcon: widget.page.accentIcon,
              ),

              const SizedBox(height: BBSpacing.px40),

              // ── Badge ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BBSpacing.px14,
                  vertical: BBSpacing.px6,
                ),
                decoration: BoxDecoration(
                  color: BBColors.brandPrimaryDim,
                  borderRadius: BBRadius.pill,
                ),
                child: Text(
                  widget.page.badge,
                  style: BBTypography.labelM.copyWith(
                    color: BBColors.brandPrimary,
                  ),
                ),
              ),

              const SizedBox(height: BBSpacing.px16),

              // ── Title ────────────────────────────────
              Text(
                widget.page.title,
                style: BBTypography.displayM,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: BBSpacing.px12),

              // ── Subtitle ─────────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  widget.page.subtitle,
                  style: BBTypography.bodyL.copyWith(
                    color: BBColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ILLUSTRATION BOX
// ─────────────────────────────────────────────────────────────

class _IllustrationBox extends StatelessWidget {
  const _IllustrationBox({
    required this.icon,
    required this.accentIcon,
  });

  final IconData icon;
  final IconData? accentIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.xxl,
        border: Border.all(color: BBColors.borderSubtle, width: 1),
        boxShadow: BBElevation.brandGlow(BBColors.brandPrimary, intensity: 0.08),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 100, color: BBColors.brandPrimary),
          if (accentIcon != null)
            Positioned(
              right: 30,
              bottom: 30,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: BBColors.bgElevated,
                  borderRadius: BBRadius.md,
                  border: Border.all(color: BBColors.borderDefault, width: 1),
                ),
                child: Icon(
                  accentIcon,
                  size: BBIconSize.lg,
                  color: BBColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DOT INDICATOR
// ─────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = active == i;
        return AnimatedContainer(
          duration: BBMotion.normal,
          curve: BBMotion.smooth,
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive ? BBColors.brandPrimary : BBColors.bgElevated,
            borderRadius: BBRadius.pill,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SPRING PHYSICS
// ─────────────────────────────────────────────────────────────

class _SpringPagePhysics extends PageScrollPhysics {
  const _SpringPagePhysics({super.parent});

  @override
  _SpringPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _SpringPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.9, stiffness: 180, damping: 22);
}
