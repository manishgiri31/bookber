import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
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
            icon: Icon(AppIcons.refresh, color: colors.textSecondary),
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
              return const BBSkeletonProfile();
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

                // ── Rating breakdown ──
                if (stats != null && stats.averageRating > 0) ...[
                  _RatingBreakdownCard(
                    averageRating: stats.averageRating,
                    totalReviews: stats.totalReviews,
                  ),
                  const SizedBox(height: BBSpacing.base),
                ],

                // ── Bio ──
                _BioBanner(initialBio: profile?.name != null
                    ? 'Passionate barber with a love for clean fades and classic cuts.'
                    : null),
                const SizedBox(height: BBSpacing.base),

                // ── Experience ──
                const _ExperienceSection(),
                const SizedBox(height: BBSpacing.base),

                // ── Account info ──
                if (email.isNotEmpty || currentUser?.phone.isNotEmpty == true)
                  _Section(
                    title: 'Account',
                    children: [
                      if (email.isNotEmpty)
                        _InfoRow(
                          icon: AppIcons.mail,
                          label: 'Email',
                          value: email,
                        ),
                      if (currentUser?.phone.isNotEmpty == true)
                        _InfoRow(
                          icon: AppIcons.phone,
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
                          icon: AppIcons.store,
                          label: 'Shop',
                          value: profile.shopName,
                        ),
                      if (profile.shopAddress.isNotEmpty)
                        _InfoRow(
                          icon: AppIcons.locationOn,
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
                      icon: AppIcons.storeAlt,
                      label: 'Manage Shop',
                      subtitle: 'Hours, chairs & gallery',
                      onTap: () => context.push('/barber/shop'),
                    ),
                    _ActionRow(
                      icon: AppIcons.scissors,
                      label: 'Services',
                      subtitle: 'Pricing, duration & categories',
                      onTap: () => context.push('/barber/services'),
                    ),
                    _ActionRow(
                      icon: AppIcons.groups,
                      label: 'Employees',
                      subtitle: 'Team management',
                      onTap: () => context.push('/barber/employees'),
                    ),
                  ],
                ),
                const SizedBox(height: BBSpacing.base),

                // ── Settings ──
                _Section(
                  title: 'Settings',
                  children: [
                    _ActionRow(
                      icon: AppIcons.lock,
                      label: 'Change Password',
                      onTap: () => context.push('/change-password'),
                    ),
                    _ActionRow(
                      icon: AppIcons.darkMode,
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
                  icon: AppIcons.logout,
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

// ── Rating Breakdown ──────────────────────────────────────────────────────────

class _RatingBreakdownCard extends StatelessWidget {
  const _RatingBreakdownCard({
    required this.averageRating,
    required this.totalReviews,
  });
  final double averageRating;
  final int totalReviews;

  static List<double> _computeDistribution(double avg) {
    final five = ((avg - 1.0) / 4.0 * 0.7 + 0.1).clamp(0.05, 0.85);
    final four = ((1.0 - five) * 0.45).clamp(0.05, 0.40);
    final three = ((1.0 - five - four) * 0.45).clamp(0.02, 0.30);
    final two = ((1.0 - five - four - three) * 0.5).clamp(0.01, 0.15);
    final one = (1.0 - five - four - three - two).clamp(0.0, 0.10);
    return [five, four, three, two, one];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final distribution = _computeDistribution(averageRating);
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RATINGS',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.md),
          Row(
            children: [
              // Big avg
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: BBTypography.textTheme.displayMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < averageRating.round()
                            ? AppIcons.starFill
                            : AppIcons.star,
                        size: 14,
                        color: BBColors.amber,
                      );
                    }),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalReviews reviews',
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: BBSpacing.xl),
              // Bar breakdown
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final stars = 5 - i;
                    final pct = distribution[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '$stars',
                            style: BBTypography.textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(AppIcons.starFill,
                              size: 10, color: BBColors.amber),
                          const SizedBox(width: BBSpacing.sm),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: colors.border,
                              valueColor: AlwaysStoppedAnimation(
                                stars >= 4
                                    ? BBColors.success
                                    : stars == 3
                                        ? BBColors.amber
                                        : BBColors.error,
                              ),
                              borderRadius:
                                  BorderRadius.circular(BBRadius.full),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(width: BBSpacing.sm),
                          Text(
                            '${(pct * 100).round()}%',
                            style: BBTypography.textTheme.labelSmall?.copyWith(
                              color: colors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bio Banner ────────────────────────────────────────────────────────────────

class _BioBanner extends StatefulWidget {
  const _BioBanner({this.initialBio});
  final String? initialBio;

  @override
  State<_BioBanner> createState() => _BioBannerState();
}

class _BioBannerState extends State<_BioBanner> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.initialBio ??
            'Tell customers about your expertise and style...');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'BIO',
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _editing = !_editing),
                child: Text(
                  _editing ? 'Save' : 'Edit',
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: BBColors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.sm),
          _editing
              ? TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  style: BBTypography.textTheme.bodyMedium
                      ?.copyWith(color: colors.text),
                  decoration: InputDecoration(
                    hintText:
                        'Describe your expertise, specialties and style...',
                    hintStyle: BBTypography.textTheme.bodyMedium
                        ?.copyWith(color: colors.textTertiary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BBRadius.md),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BBRadius.md),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BBRadius.md),
                      borderSide:
                          const BorderSide(color: BBColors.amber, width: 1.5),
                    ),
                  ),
                )
              : Text(
                  _ctrl.text,
                  style: BBTypography.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Experience Section ────────────────────────────────────────────────────────

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection();

  static const _specialties = [
    'Skin Fade', 'Classic Cut', 'Beard Trim',
    'Hair Wash', 'Kids Cuts', 'Line Up',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPERIENCE',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.md),
          Row(
            children: [
              _ExpStat(label: 'Years', value: '5+'),
              const SizedBox(width: BBSpacing.sm),
              _ExpStat(label: 'Clients', value: '2.4k'),
              const SizedBox(width: BBSpacing.sm),
              _ExpStat(label: 'Services', value: '6'),
            ],
          ),
          const SizedBox(height: BBSpacing.md),
          Text(
            'Specialties',
            style: BBTypography.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Wrap(
            spacing: BBSpacing.sm,
            runSpacing: BBSpacing.sm,
            children: _specialties.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BBColors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(BBRadius.full),
                border: Border.all(
                    color: BBColors.amber.withValues(alpha: 0.25)),
              ),
              child: Text(
                s,
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: BBColors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _ExpStat extends StatelessWidget {
  const _ExpStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: BBSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(BBRadius.md),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: BBTypography.textTheme.titleLarge?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
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
          icon: AppIcons.calendar,
          color: colors.accent,
        ),
        const SizedBox(width: BBSpacing.sm),
        _StatCard(
          label: 'Done',
          value: stats.completedToday.toString(),
          icon: AppIcons.checkCircle,
          color: BBColors.success,
        ),
        const SizedBox(width: BBSpacing.sm),
        _StatCard(
          label: 'In Queue',
          value: stats.activeQueue.toString(),
          icon: AppIcons.people,
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
            Icon(AppIcons.arrowForwardSmall,
                size: 14, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
