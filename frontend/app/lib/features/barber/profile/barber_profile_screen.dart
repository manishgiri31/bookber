import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';

class BarberProfileScreen extends ConsumerWidget {
  const BarberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgCanvas,
        title: Text(
          'My Profile',
          style: BBTypography.headingL.copyWith(color: colors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: BBSpacing.px8),
        children: [
          // ── Header card ──────────────────────────────────────
          Container(
            margin: BBSpacing.pagePadding.copyWith(
                top: BBSpacing.px16, bottom: BBSpacing.px8),
            padding: BBSpacing.cardPadding,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BBRadius.card,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                _Avatar(name: user?.name ?? 'Barber'),
                const SizedBox(width: BBSpacing.px16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Barber',
                        style: BBTypography.displayS
                            .copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: BBSpacing.px4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: BBSpacing.px8,
                                vertical: BBSpacing.px2),
                            decoration: BoxDecoration(
                              color: BBColors.brandPrimaryDim,
                              borderRadius: BBRadius.pill,
                            ),
                            child: Text(
                              'BARBER',
                              style: BBTypography.overline
                                  .copyWith(color: BBColors.brandPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: BBSpacing.px4),
                      Text(
                        user?.email ?? '',
                        style: BBTypography.bodyS
                            .copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: BBIconSize.md, color: colors.textSecondary),
                  onPressed: () => context.push(RoutePaths.editProfile),
                ),
              ],
            ),
          ),

          // ── Quick stats ──────────────────────────────────────
          Padding(
            padding: BBSpacing.pagePadding
                .copyWith(top: BBSpacing.px8, bottom: BBSpacing.px16),
            child: Row(
              children: [
                _StatCard(
                    label: 'Completed',
                    value: '—',
                    icon: Icons.check_circle_outline,
                    colors: colors),
                const SizedBox(width: BBSpacing.px12),
                _StatCard(
                    label: 'Avg Rating',
                    value: '—',
                    icon: Icons.star_outline_rounded,
                    colors: colors),
                const SizedBox(width: BBSpacing.px12),
                _StatCard(
                    label: 'In Queue',
                    value: '—',
                    icon: Icons.people_outline_rounded,
                    colors: colors),
              ],
            ),
          ),

          _SectionHeader(label: 'Account', colors: colors),
          _Tile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
            colors: colors,
            onTap: () => context.push(RoutePaths.editProfile),
          ),
          _Tile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            colors: colors,
            onTap: () => context.push(RoutePaths.changePassword),
          ),
          _Tile(
            icon: Icons.schedule_outlined,
            label: 'My Schedule',
            colors: colors,
            onTap: () => context.go(RoutePaths.barberSchedule),
          ),

          _SectionHeader(label: 'Appearance', colors: colors),
          _ThemeToggleTile(themeMode: themeMode, colors: colors, ref: ref),

          _SectionHeader(label: 'Support', colors: colors),
          _Tile(
            icon: Icons.help_outline_rounded,
            label: 'Help & FAQ',
            colors: colors,
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Help & FAQ'),
                content: const Text(
                    'For support, email us at support@bookber.app\nor visit our website for FAQs and guides.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
          _Tile(
            icon: Icons.info_outline_rounded,
            label: 'About BookBer',
            trailing: Text(
              'v1.0.0',
              style: BBTypography.bodyM.copyWith(color: colors.textDisabled),
            ),
            colors: colors,
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('About BookBer'),
                content: const Text(
                    'BookBer v1.0.0\n\nThe smart barber booking platform that connects customers with local barbershops for seamless queue management and appointments.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: BBSpacing.px24),

          Padding(
            padding: BBSpacing.pagePadding,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: BBColors.error,
                side: const BorderSide(color: BBColors.error),
                minimumSize: const Size(double.infinity, BBTouchTarget.button),
                shape: const RoundedRectangleBorder(
                    borderRadius: BBRadius.pill),
              ),
              icon: const Icon(Icons.logout_rounded, size: BBIconSize.md),
              label: const Text('Sign Out'),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go(RoutePaths.login);
              },
            ),
          ),

          const SizedBox(height: BBSpacing.px32),
        ],
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [BBColors.brandPrimary, Color(0xFF5540DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: BBTypography.headingL.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
  });

  final String label, value;
  final IconData icon;
  final BBColorTheme colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(BBSpacing.px12),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BBRadius.md,
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, size: BBIconSize.md, color: BBColors.brandPrimary),
            const SizedBox(height: BBSpacing.px4),
            Text(value,
                style: BBTypography.headingM.copyWith(color: colors.textPrimary)),
            Text(label,
                style: BBTypography.caption.copyWith(color: colors.textDisabled),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colors});
  final String label;
  final BBColorTheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BBSpacing.px20, BBSpacing.px20, BBSpacing.px20, BBSpacing.px6),
      child: Text(
        label.toUpperCase(),
        style: BBTypography.overline.copyWith(color: colors.textDisabled),
      ),
    );
  }
}

// ── Tile ───────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final BBColorTheme colors;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: BBIconSize.md, color: colors.textSecondary),
      title: Text(label,
          style: BBTypography.bodyL.copyWith(color: colors.textPrimary)),
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded,
              size: BBIconSize.md, color: colors.textDisabled),
      onTap: onTap,
    );
  }
}

// ── Theme toggle tile ──────────────────────────────────────────

class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile({
    required this.themeMode,
    required this.colors,
    required this.ref,
  });

  final ThemeMode themeMode;
  final BBColorTheme colors;
  final WidgetRef ref;

  IconData get _icon => switch (themeMode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };

  String get _label => switch (themeMode) {
        ThemeMode.light => 'Light Mode',
        ThemeMode.dark => 'Dark Mode',
        ThemeMode.system => 'System Default',
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_icon, size: BBIconSize.md, color: colors.textSecondary),
      title: Text(
        _label,
        style: BBTypography.bodyL.copyWith(color: colors.textPrimary),
      ),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined),
          ),
        ],
        selected: {themeMode},
        onSelectionChanged: (modes) =>
            ref.read(themeModeProvider.notifier).setMode(modes.first),
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: BBColors.brandPrimaryDim,
          selectedForegroundColor: BBColors.brandPrimary,
          foregroundColor: colors.textSecondary,
          side: BorderSide(color: colors.border, width: 1),
        ),
      ),
    );
  }
}
