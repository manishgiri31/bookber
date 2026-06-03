import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/design_system.dart';
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
    _OnboardingPageData(
      icon: _OnboardingIcon.queue,
      title: 'Skip the Queue',
      subtitle:
          'Book your barber in seconds. No calls, no waiting - just show up fresh.',
    ),
    _OnboardingPageData(
      icon: _OnboardingIcon.chair,
      title: 'Your Chair, Reserved',
      subtitle:
          'BookBer barbers hold dedicated chairs just for app users. Guaranteed, every time.',
    ),
    _OnboardingPageData(
      icon: _OnboardingIcon.liveQueue,
      title: 'Live Queue Updates',
      subtitle:
          'See real-time wait times, track your position, and get notified when it\'s your turn.',
    ),
  ];

  @override
  void initState() {
    super.initState();
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
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await ref.read(markOnboardingCompleteProvider.future);
    if (mounted) {
      context.go('/login');
    }
  }

  void _handleSkip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const _SpringPagePhysics(),
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _OnboardingPage(
                key: ValueKey(_pages[index].title),
                page: _pages[index],
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: _currentPage == _pages.length - 1 ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: _currentPage == _pages.length - 1,
                  child: TextButton(
                    onPressed: _handleSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: BookBerPalette.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: BookBerPalette.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: BookBerPalette.bgPrimary,
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PageIndicator(
                    pageCount: _pages.length,
                    currentPage: _currentPage,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: BookBerPalette.primaryAccent,
                        foregroundColor: BookBerPalette.bgPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: BookBerPalette.bgPrimary,
                        ),
                      ),
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

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final _OnboardingIcon icon;
  final String title;
  final String subtitle;
}

class _OnboardingPage extends StatefulWidget {
  const _OnboardingPage({super.key, required this.page});

  final _OnboardingPageData page;

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 88, 24, 176),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IllustrationPlaceholder(icon: widget.page.icon),
            const SizedBox(height: 48),
            Text(
              widget.page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: BookBerPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                widget.page.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  height: 1.45,
                  color: BookBerPalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? BookBerPalette.primaryAccent
                : BookBerPalette.bgElevated,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

enum _OnboardingIcon { queue, chair, liveQueue }

class _IllustrationPlaceholder extends StatelessWidget {
  const _IllustrationPlaceholder({required this.icon});

  final _OnboardingIcon icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BookBerPalette.bgElevated),
      ),
      child: Center(child: _buildIcon()),
    );
  }

  Widget _buildIcon() {
    switch (icon) {
      case _OnboardingIcon.queue:
        return const Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 118,
              color: BookBerPalette.primaryAccent,
            ),
            Positioned(
              right: 56,
              bottom: 54,
              child: Icon(
                Icons.content_cut_rounded,
                size: 78,
                color: BookBerPalette.textPrimary,
              ),
            ),
          ],
        );
      case _OnboardingIcon.chair:
        return const Icon(
          Icons.chair_alt_rounded,
          size: 118,
          color: BookBerPalette.primaryAccent,
        );
      case _OnboardingIcon.liveQueue:
        return const Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.format_list_numbered_rounded,
              size: 118,
              color: BookBerPalette.primaryAccent,
            ),
            Positioned(
              right: 62,
              top: 58,
              child: Icon(
                Icons.bolt_rounded,
                size: 58,
                color: BookBerPalette.textPrimary,
              ),
            ),
          ],
        );
    }
  }
}

class _SpringPagePhysics extends PageScrollPhysics {
  const _SpringPagePhysics({super.parent});

  @override
  _SpringPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _SpringPagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring {
    return const SpringDescription(
      mass: 0.9,
      stiffness: 180,
      damping: 22,
    );
  }
}
