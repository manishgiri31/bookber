import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_icons.dart';
import '../../core/design/bb_colors.dart';
import '../../core/design/bb_tokens.dart';
import '../../core/design/bb_typography.dart';
import '../shared/domain/booking_models.dart';
import 'home/home_provider.dart';

class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reopening the app should re-check for an active booking, the same way
    // a ride-hailing app resumes straight into an in-progress ride.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(activeBookingsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFor(location);

    // Only take over navigation from the Home tab itself — a booking becoming
    // active shouldn't yank the user out of Shops/Bookings/Profile.
    ref.listen<AsyncValue<List<Booking>>>(activeBookingsProvider, (prev, next) {
      final booking = next.valueOrNull?.firstOrNull;
      if (booking == null) return;
      final currentPath = GoRouterState.of(context).uri.path;
      if (currentPath != '/home') return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/queue/${booking.id}');
      });
    });

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BBRadius.xxl),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BBRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.6 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: AppIcons.home,
                  activeIcon: AppIcons.homeActive,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                _NavItem(
                  icon: AppIcons.shops,
                  activeIcon: AppIcons.shopsActive,
                  label: 'Shops',
                  selected: currentIndex == 1,
                  onTap: () => context.go('/shops'),
                ),
                _NavItem(
                  icon: AppIcons.receipt,
                  activeIcon: AppIcons.receiptFill,
                  label: 'Bookings',
                  selected: currentIndex == 2,
                  onTap: () => context.go('/bookings'),
                ),
                _NavItem(
                  icon: AppIcons.profile,
                  activeIcon: AppIcons.profileActive,
                  label: 'Profile',
                  selected: currentIndex == 3,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _indexFor(String path) {
    if (path.startsWith('/shops')) return 1;
    if (path.startsWith('/bookings') || path.startsWith('/queue')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey(selected),
                size: 22,
                color: selected ? colors.accent : colors.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: selected ? colors.accent : colors.textTertiary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 18 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(BBRadius.full),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

