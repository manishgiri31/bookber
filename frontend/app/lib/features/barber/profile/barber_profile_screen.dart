import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_error_widget.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../auth/data/auth_provider.dart';
import '../dashboard/barber_provider.dart';

class BarberProfileScreen extends ConsumerStatefulWidget {
  const BarberProfileScreen({super.key});

  @override
  ConsumerState<BarberProfileScreen> createState() =>
      _BarberProfileScreenState();
}

class _BarberProfileScreenState extends ConsumerState<BarberProfileScreen> {
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final dash = ref.watch(barberDashProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textSecondary),
            onPressed: dash.isLoading
                ? null
                : () => ref.read(barberDashProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colors.accent,
        onRefresh: () => ref.read(barberDashProvider.notifier).refresh(),
        child: Builder(
          builder: (context) {
            if (dash.isLoading && dash.profile == null) {
              return const Center(child: BBLoader());
            }

            if (dash.error != null && dash.profile == null) {
              return BBErrorWidget(
                error: dash.error!,
                onRetry: () => ref.read(barberDashProvider.notifier).refresh(),
              );
            }

            final profile = dash.profile;
            final stats = dash.stats;
            final name = profile?.name ?? currentUser?.name ?? '';
            final email = profile?.email ?? currentUser?.email ?? '';
            final initials = name.isNotEmpty ? name[0].toUpperCase() : 'B';

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.pageHorizontal,
                vertical: BBSpacing.pageVertical,
              ),
              children: [
                // ── Avatar + name ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colors.accent
                              .withValues(alpha: context.isDark ? 0.15 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style:
                                BBTypography.textTheme.displaySmall?.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: BBSpacing.md),
                      if (name.isNotEmpty)
                        Text(
                          name,
                          style:
                              BBTypography.textTheme.headlineMedium?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: BBSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(
                                  alpha: context.isDark ? 0.15 : 0.08),
                              borderRadius:
                                  BorderRadius.circular(BBRadius.full),
                            ),
                            child: Text(
                              'BARBER',
                              style: BBTypography.textTheme.labelSmall?.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (profile != null) ...[
                            const SizedBox(width: BBSpacing.xs),
                            _AvailabilityPill(
                              isAvailable: profile.isAvailable,
                              onTap: () => ref
                                  .read(barberDashProvider.notifier)
                                  .toggleAvailability(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BBSpacing.xl),

                // ── Stats row ──
                if (stats != null) ...[
                  _StatsRow(stats: stats),
                  const SizedBox(height: BBSpacing.xl),
                ],

                // ── Account info ──
                if (email.isNotEmpty || currentUser?.phone.isNotEmpty == true)
                  _Section(
                    title: 'Account',
                    children: [
                      if (email.isNotEmpty)
                        _InfoRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          value: email,
                        ),
                      if (currentUser?.phone.isNotEmpty == true)
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: currentUser!.phone,
                        ),
                    ],
                  ),
                if (email.isNotEmpty || currentUser?.phone.isNotEmpty == true)
                  const SizedBox(height: BBSpacing.base),

                // ── Work info ──
                if (profile != null &&
                    (profile.shopName.isNotEmpty ||
                        profile.shopAddress.isNotEmpty))
                  _Section(
                    title: 'Work',
                    children: [
                      if (profile.shopName.isNotEmpty)
                        _InfoRow(
                          icon: Icons.store_outlined,
                          label: 'Shop',
                          value: profile.shopName,
                        ),
                      if (profile.shopAddress.isNotEmpty)
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: profile.shopAddress,
                        ),
                    ],
                  ),
                if (profile != null &&
                    (profile.shopName.isNotEmpty ||
                        profile.shopAddress.isNotEmpty))
                  const SizedBox(height: BBSpacing.base),

                // ── Shop Management ──
                _Section(
                  title: 'Shop',
                  children: [
                    _ActionRow(
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
                  children: [
                    _ActionRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      onTap: () => context.push('/change-password'),
                    ),
                    _ActionRow(
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
                  onPressed:
                      _signingOut ? null : () => _confirmSignOut(context),
                  loading: _signingOut,
                  icon: Icons.logout_rounded,
                ),
                const SizedBox(height: BBSpacing.base),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
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
    if (ok != true || !context.mounted) return;
    setState(() => _signingOut = true);
    await ref.read(authProvider.notifier).logout();
    if (mounted) setState(() => _signingOut = false);
  }
}

// ── Availability pill ─────────────────────────────────────────────────────────

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.isAvailable, required this.onTap});
  final bool isAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isAvailable
              ? BBColors.success.withValues(alpha: 0.12)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(BBRadius.full),
          border: Border.all(
            color: isAvailable
                ? BBColors.success.withValues(alpha: 0.4)
                : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color:
                    isAvailable ? BBColors.success : colors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isAvailable ? 'Available' : 'Away',
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color:
                    isAvailable ? BBColors.success : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

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
          color: colors.accent,
        ),
        const SizedBox(width: BBSpacing.sm),
        _StatCard(
          label: 'Done',
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
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: BBSpacing.md,
          horizontal: BBSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
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

// ── Shared layout widgets ─────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: BBSpacing.xs, bottom: BBSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children
                .expand(
                  (c) => [
                    c,
                    if (c != children.last)
                      Divider(color: colors.border, height: 1, indent: 52),
                  ],
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
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
