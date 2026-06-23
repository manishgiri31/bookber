import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../auth/data/auth_provider.dart';
import '../dashboard/barber_provider.dart';

class BarberProfileScreen extends ConsumerWidget {
  const BarberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final dash = ref.watch(barberDashProvider);
    final profile = dash.profile;
    final stats = dash.stats;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.pageVertical,
        ),
        children: [
          // ── Avatar + name ──
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: BBColors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BBColors.amber.withValues(alpha: 0.35),
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          profile?.name.isNotEmpty == true
                              ? profile!.name[0].toUpperCase()
                              : 'B',
                          style:
                              BBTypography.textTheme.displaySmall?.copyWith(
                            color: BBColors.amber,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BBSpacing.md),
                Text(
                  profile?.name ?? '—',
                  style: BBTypography.textTheme.headlineMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BBSpacing.xs),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: BBColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: Text(
                    'BARBER',
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                // Availability toggle pill
                if (profile != null) ...[
                  const SizedBox(height: BBSpacing.sm),
                  GestureDetector(
                    onTap: () => ref
                        .read(barberDashProvider.notifier)
                        .toggleAvailability(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: profile.isAvailable
                            ? BBColors.success.withValues(alpha: 0.12)
                            : colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(BBRadius.full),
                        border: Border.all(
                          color: profile.isAvailable
                              ? BBColors.success.withValues(alpha: 0.4)
                              : colors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: profile.isAvailable
                                  ? BBColors.success
                                  : colors.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            profile.isAvailable ? 'Available' : 'Away',
                            style: BBTypography.textTheme.labelMedium?.copyWith(
                              color: profile.isAvailable
                                  ? BBColors.success
                                  : colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

              ],
            ),
          ),
          const SizedBox(height: BBSpacing.xl),

          // ── Stats row ──
          if (stats != null) ...[
            _StatsRow(stats: stats),
            const SizedBox(height: BBSpacing.xl),
          ],

          // ── Work info ──
          if (profile != null)
            _Section(
              title: 'Work',
              items: [
                _InfoItem(
                  icon: Icons.store_outlined,
                  label: 'Shop',
                  value: profile.shopName,
                ),
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: profile.shopAddress,
                ),
                if (profile.email != null)
                  _InfoItem(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: profile.email!,
                  ),
              ],
            ),
          const SizedBox(height: BBSpacing.base),

          // ── Shop Management ──
          _Section(
            title: 'Shop',
            items: [
              _ActionItem(
                icon: Icons.store_mall_directory_outlined,
                label: 'Manage Shop',
                subtitle: 'Services, schedule & info',
                onTap: () => context.push('/barber/shop'),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),

          // ── Settings ──
          _Section(
            title: 'Settings',
            items: [
              _ActionItem(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => context.push('/change-password'),
              ),
              _ActionItem(
                icon: Icons.dark_mode_outlined,
                label: 'Appearance',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.xl),

          BBButton(
            label: 'Sign Out',
            variant: BBButtonVariant.destructive,
            onPressed: () => _signOut(context, ref),
            icon: Icons.logout_rounded,
          ),
          const SizedBox(height: BBSpacing.base),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: BBColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final BarberStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Row(
      children: [
        _StatCard(
          label: 'Today',
          value: stats.todayBookings.toString(),
          icon: Icons.calendar_today_rounded,
        ),
        const SizedBox(width: BBSpacing.sm),
        _StatCard(
          label: 'Completed',
          value: stats.completedToday.toString(),
          icon: Icons.check_circle_outline_rounded,
          color: BBColors.success,
        ),
        const SizedBox(width: BBSpacing.sm),
        _StatCard(
          label: 'In Queue',
          value: stats.activeQueue.toString(),
          icon: Icons.people_outline_rounded,
          color: colors.textSecondary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final accent = color ?? BBColors.amber;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(BBSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(height: 4),
            Text(
              value,
              style: BBTypography.textTheme.titleLarge?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: BBTypography.textTheme.labelSmall
                  ?.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label.toUpperCase(),
        style: BBTypography.textTheme.labelSmall?.copyWith(
          color: colors.textTertiary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: title),
        const SizedBox(height: BBSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: items
                .expand(
                  (c) => [
                    c,
                    if (c != items.last)
                      Divider(
                        color: colors.border,
                        height: 1,
                        indent: 52,
                      ),
                  ],
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.base,
        vertical: BBSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: BBTypography.textTheme.bodyMedium?.copyWith(
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.base,
          vertical: BBSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.textSecondary),
            const SizedBox(width: BBSpacing.md),
            Expanded(
              child: subtitle != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: BBTypography.textTheme.bodyMedium
                              ?.copyWith(color: colors.text),
                        ),
                        Text(
                          subtitle!,
                          style: BBTypography.textTheme.labelSmall
                              ?.copyWith(color: colors.textTertiary),
                        ),
                      ],
                    )
                  : Text(
                      label,
                      style: BBTypography.textTheme.bodyMedium
                          ?.copyWith(color: colors.text),
                    ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
