import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_text_field.dart';
import '../../auth/data/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
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
                    color: colors.accent.withValues(alpha: context.isDark ? 0.15 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: BBTypography.textTheme.displaySmall?.copyWith(
                        color: colors.accent,
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
                    color: colors.accent.withValues(alpha: context.isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: colors.accent,
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
                icon: AppIcons.mail,
                label: 'Email',
                value: user.email,
              ),
              _InfoRow(
                icon: AppIcons.phone,
                label: 'Phone',
                value: user.phone.isNotEmpty ? user.phone : 'Tap to add',
                onEdit: () => _editPhone(context, user.phone),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),

          _Section(
            title: 'Activity',
            children: [
              _ActionRow(
                icon: AppIcons.history,
                label: 'Booking History',
                onTap: () => context.push('/bookings'),
              ),
              _ActionRow(
                icon: AppIcons.star,
                label: 'My Reviews',
                onTap: () => context.push('/reviews'),
              ),
              _ActionRow(
                icon: AppIcons.receiptFill,
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
                icon: AppIcons.wallet,
                label: 'Wallet',
                onTap: () => context.push('/wallet'),
              ),
              _ActionRow(
                icon: AppIcons.loyalty,
                label: 'Loyalty Points',
                onTap: () => context.push('/loyalty'),
              ),
              _ActionRow(
                icon: AppIcons.gift,
                label: 'Referrals',
                onTap: () => context.push('/referral'),
              ),
              _ActionRow(
                icon: AppIcons.favorite,
                label: 'Favourites',
                onTap: () => context.push('/favourites'),
              ),
              _ActionRow(
                icon: AppIcons.trophy,
                label: 'Achievements',
                onTap: () => context.push('/gamification'),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),

          _Section(
            title: 'Settings',
            children: [
              _ActionRow(
                icon: AppIcons.bell,
                label: 'Notification Preferences',
                onTap: () => context.push('/settings/notifications'),
              ),
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
              _ActionRow(
                icon: AppIcons.privacy,
                label: 'Privacy & Security',
                onTap: () => context.push('/settings/privacy'),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),

          _Section(
            title: 'Support',
            children: [
              _ActionRow(
                icon: AppIcons.helpOutline,
                label: 'Help Centre',
                onTap: () => context.push('/help'),
              ),
              _ActionRow(
                icon: AppIcons.chat,
                label: 'Contact Support',
                onTap: () => context.push('/support'),
              ),
              _ActionRow(
                icon: AppIcons.info,
                label: 'About BookBer',
                onTap: () => context.push('/about'),
              ),
              _ActionRow(
                icon: AppIcons.description,
                label: 'Terms & Privacy',
                onTap: () => context.push('/terms'),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.xl),

          BBButton(
            label: 'Sign Out',
            variant: BBButtonVariant.destructive,
            onPressed: _signingOut ? null : () => _confirmSignOut(context),
            loading: _signingOut,
            icon: AppIcons.logout,
          ),
          const SizedBox(height: BBSpacing.sm),
          Center(
            child: Text(
              'BookBer v2.0.0',
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: context.bbColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: BBSpacing.base),
        ],
      ),
    );
  }

  void _editPhone(BuildContext context, String currentPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BBRadius.xxl)),
      ),
      builder: (ctx) => _EditPhoneSheet(
        currentPhone: currentPhone,
        onSave: (phone) async {
          await ref.read(authProvider.notifier).updateProfile(phone: phone);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
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

class _EditPhoneSheet extends StatefulWidget {
  const _EditPhoneSheet({required this.currentPhone, required this.onSave});
  final String currentPhone;
  final Future<void> Function(String) onSave;

  @override
  State<_EditPhoneSheet> createState() => _EditPhoneSheetState();
}

class _EditPhoneSheetState extends State<_EditPhoneSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.currentPhone.isNotEmpty ? widget.currentPhone : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: EdgeInsets.only(
        left: BBSpacing.pageHorizontal,
        right: BBSpacing.pageHorizontal,
        top: BBSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + BBSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Phone Number',
                style: BBTypography.textTheme.headlineSmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(AppIcons.close, color: colors.textTertiary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.xs),
          Text(
            'Add your phone number to enable SMS notifications and faster check-in.',
            style: BBTypography.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: BBSpacing.base),
          BBTextField(
            label: 'Phone',
            hint: '+91 98765 43210',
            controller: _ctrl,
            keyboardType: TextInputType.phone,
            prefixIcon: AppIcons.phone,
            errorText: _error,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: BBSpacing.base),
          BBButton(
            label: 'Save',
            onPressed: _save,
            loading: _saving,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.onSave(_ctrl.text.trim());
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _saving = false;
        });
      }
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
    this.onEdit,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return InkWell(
      onTap: onEdit,
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
                      color: onEdit != null && value == 'Tap to add'
                          ? colors.textTertiary
                          : colors.text,
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              Icon(
                AppIcons.edit,
                size: 16,
                color: colors.textTertiary,
              ),
          ],
        ),
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
              AppIcons.arrowForwardSmall,
              size: 14,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
