import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/bb_colors.dart';
import '../../core/design/bb_tokens.dart';
import '../../core/design/bb_typography.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.store_outlined,
                activeIcon: Icons.store_rounded,
                label: 'Shops',
                selected: currentIndex == 1,
                onTap: () => context.go('/shops'),
              ),
              _NavItem(
                icon: Icons.queue_outlined,
                activeIcon: Icons.queue_rounded,
                label: 'Queue',
                selected: currentIndex == 2,
                onTap: () => context.go('/bookings'),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                selected: currentIndex == 3,
                onTap: () => context.go('/profile'),
              ),
            ],
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BBSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                size: 22,
                color: selected ? BBColors.amber : colors.textTertiary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: selected ? BBColors.amber : colors.textTertiary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
