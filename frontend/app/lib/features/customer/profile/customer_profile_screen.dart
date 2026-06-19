import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

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
          'Profile',
          style: BBTypography.headingL.copyWith(color: colors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                size: BBIconSize.lg, color: colors.textPrimary),
            onPressed: () => context.push(RoutePaths.notifications),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: BBSpacing.px8),
        children: [
          // ── Avatar + name ───────────────────────────────────
          Padding(
            padding: BBSpacing.pagePadding.copyWith(
              top: BBSpacing.px24,
              bottom: BBSpacing.px24,
            ),
            child: Row(
              children: [
                _Avatar(name: user?.name ?? 'Guest'),
                const SizedBox(width: BBSpacing.px16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Guest',
                        style: BBTypography.displayS
                            .copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: BBSpacing.px4),
                      Text(
                        user?.email ?? '',
                        style: BBTypography.bodyM
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
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            trailing: Text(
              user?.phone ?? 'Not set',
              style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
            ),
            colors: colors,
            onTap: () => _showPhoneDialog(context, user?.phone),
          ),
          _Tile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            colors: colors,
            onTap: () => context.push(RoutePaths.notifications),
          ),

          _SectionHeader(label: 'Appearance', colors: colors),
          _ThemeToggleTile(themeMode: themeMode, colors: colors, ref: ref),

          _SectionHeader(label: 'Activity', colors: colors),
          _Tile(
            icon: Icons.calendar_today_outlined,
            label: 'Booking History',
            colors: colors,
            onTap: () => context.go(RoutePaths.history),
          ),
          _Tile(
            icon: Icons.star_border_rounded,
            label: 'My Reviews',
            colors: colors,
            onTap: () => context.push(RoutePaths.myReviews),
          ),
          _Tile(
            icon: Icons.location_on_outlined,
            label: 'Nearby Shops',
            colors: colors,
            onTap: () => context.go(RoutePaths.explore),
          ),

          _SectionHeader(label: 'Support', colors: colors),
          _Tile(
            icon: Icons.help_outline_rounded,
            label: 'Help & FAQ',
            colors: colors,
            onTap: () => _showInfoDialog(
              context,
              title: 'Help & FAQ',
              content: 'For support, email us at support@bookber.app\nor visit our website for FAQs and guides.',
            ),
          ),
          _Tile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            colors: colors,
            onTap: () => _showInfoDialog(
              context,
              title: 'Privacy Policy',
              content: 'BookBer collects only the data necessary to provide booking services. We do not sell your personal information to third parties. Your data is encrypted and stored securely.',
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
            onTap: () => _showInfoDialog(
              context,
              title: 'About BookBer',
              content: 'BookBer v1.0.0\n\nThe smart barber booking platform that connects customers with local barbershops for seamless queue management and appointments.',
            ),
          ),

          const SizedBox(height: BBSpacing.px24),

          // ── Sign out ────────────────────────────────────────
          Padding(
            padding: BBSpacing.pagePadding,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: BBColors.error,
                side: const BorderSide(color: BBColors.error),
                minimumSize: const Size(double.infinity, BBTouchTarget.button),
                shape: const RoundedRectangleBorder(borderRadius: BBRadius.pill),
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

void _showPhoneDialog(BuildContext context, String? currentPhone) {
  final ctrl = TextEditingController(text: currentPhone ?? '');
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Phone Number'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(hintText: '+91 9876543210'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number saved.')),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showInfoDialog(BuildContext context, {required String title, required String content}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
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
