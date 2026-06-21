import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../auth/data/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colors = context.bbColors;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.pageHorizontal,
          vertical: BBSpacing.pageVertical,
        ),
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: BBColors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: BBTypography.textTheme.displaySmall?.copyWith(
                        color: BBColors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: BBSpacing.md),
                Text(
                  user.name,
                  style: BBTypography.textTheme.headlineMedium?.copyWith(
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: BBSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: BBSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: BBColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpacing.xl),

          // Info section
          _Section(
            title: 'Account',
            children: [
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: user.email,
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phone.isNotEmpty ? user.phone : 'Not set',
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),

          _Section(
            title: 'Activity',
            children: [
              _ActionRow(
                icon: Icons.history_rounded,
                label: 'Booking History',
                onTap: () => context.push('/bookings'),
              ),
              _ActionRow(
                icon: Icons.star_outline_rounded,
                label: 'My Reviews',
                onTap: () => context.push('/reviews'),
              ),
              _ActionRow(
                icon: Icons.receipt_long_rounded,
                label: 'Payment History',
                onTap: () => context.push('/payments/history'),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),

          _Section(
            title: 'Rewards',
            children: [
              _ActionRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet',
                onTap: () => context.push('/wallet'),
              ),
              _ActionRow(
                icon: Icons.military_tech_rounded,
                label: 'Loyalty Points',
                onTap: () => context.push('/loyalty'),
              ),
              _ActionRow(
                icon: Icons.card_giftcard_rounded,
                label: 'Referrals',
                onTap: () => context.push('/referral'),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),

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
            onPressed: () => _confirmSignOut(context, ref),
            icon: Icons.logout_rounded,
          ),
          const SizedBox(height: BBSpacing.base),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
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
          padding: const EdgeInsets.only(
              left: BBSpacing.xs, bottom: BBSpacing.sm),
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
  });
  final IconData icon;
  final String label;
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
              child: Text(
                label,
                style: BBTypography.textTheme.bodyMedium?.copyWith(
                  color: colors.text,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
