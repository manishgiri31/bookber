import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_icons.dart';
import '../../core/design/bb_colors.dart';
import '../../core/design/bb_tokens.dart';
import '../../core/design/bb_typography.dart';

class BarberShell extends StatelessWidget {
  const BarberShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final location = GoRouterState.of(context).uri.path;
    final idx = _indexFor(location);

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
                icon: AppIcons.dashboard,
                activeIcon: AppIcons.dashboardFill,
                label: 'Dashboard',
                selected: idx == 0,
                onTap: () => context.go('/barber'),
              ),
              _NavItem(
                icon: AppIcons.queue,
                activeIcon: AppIcons.queueFill,
                label: 'Queue',
                selected: idx == 1,
                onTap: () => context.go('/barber/queue'),
              ),
              _NavItem(
                icon: AppIcons.calendarMonth,
                activeIcon: AppIcons.calendarFill,
                label: 'Bookings',
                selected: idx == 2,
                onTap: () => context.go('/barber/bookings'),
              ),
              _NavItem(
                icon: AppIcons.profile,
                activeIcon: AppIcons.profileActive,
                label: 'Profile',
                selected: idx == 3,
                onTap: () => context.go('/barber/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _indexFor(String p) {
    if (p.startsWith('/barber/queue')) return 1;
    if (p.startsWith('/barber/bookings')) return 2;
    if (p.startsWith('/barber/profile')) return 3;
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
                color: selected ? colors.accent : colors.textTertiary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: selected ? colors.accent : colors.textTertiary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
