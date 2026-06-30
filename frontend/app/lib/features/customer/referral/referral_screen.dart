import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart' show showBBSnackbar;

final _referralProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.read(apiClientProvider);
  final results = await Future.wait<dynamic>([
    client.get<dynamic>(ApiEndpoints.referralMyCode),
    client.get<dynamic>(ApiEndpoints.referralMyReferrals),
  ]);
  final codeRes = results[0] is Map<String, dynamic>
      ? results[0] as Map<String, dynamic>
      : <String, dynamic>{};
  final referralsRes = results[1] is Map<String, dynamic>
      ? results[1] as Map<String, dynamic>
      : <String, dynamic>{};
  return {
    'code': codeRes['code'] as String? ?? '',
    'referrals': (referralsRes['referrals'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ?? [],
  };
});

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_referralProvider);
    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Referrals')),
      body: async.when(
        loading: () => const BBSkeletonListView(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (data) {
          final code = data['code'] as String;
          final referrals = data['referrals'] as List<Map<String, dynamic>>;
          final completed =
              referrals.where((r) => r['status'] == 'COMPLETED').length;

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.pageHorizontal,
              vertical: BBSpacing.pageVertical,
            ),
            children: [
              _ReferralCodeCard(code: code),
              const SizedBox(height: BBSpacing.base),
              _StatsCard(total: referrals.length, completed: completed),
              const SizedBox(height: BBSpacing.xl),
              Text(
                'APPLY A REFERRAL CODE',
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: BBSpacing.sm),
              _ApplyCodeSection(onApplied: () => ref.invalidate(_referralProvider)),
              const SizedBox(height: BBSpacing.xl),
              if (referrals.isNotEmpty) ...[
                Text(
                  'YOUR REFERRALS',
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: BBSpacing.sm),
                ...referrals.map((r) => _ReferralItem(referral: r)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.xl),
      decoration: BoxDecoration(
        color: BBColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border:
            Border.all(color: BBColors.amber.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(AppIcons.gift,
              color: BBColors.amber, size: 36),
          const SizedBox(height: BBSpacing.sm),
          Text(
            'Your Referral Code',
            style: BBTypography.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              showBBSnackbar(context, message: 'Code copied!');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: BBSpacing.lg, vertical: BBSpacing.sm),
              decoration: BoxDecoration(
                color: BBColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(BBRadius.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: BBTypography.textTheme.headlineSmall?.copyWith(
                      color: BBColors.amber,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: BBSpacing.sm),
                  const Icon(AppIcons.copy,
                      color: BBColors.amber, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Text(
            'Earn 50 points when your friend completes their first booking',
            textAlign: TextAlign.center,
            style: BBTypography.textTheme.bodySmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.total, required this.completed});
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
              child: _Stat(
                  label: 'Total Referrals', value: total.toString())),
          Container(width: 1, height: 40, color: colors.border),
          Expanded(
              child: _Stat(
                  label: 'Completed', value: completed.toString())),
          Container(width: 1, height: 40, color: colors.border),
          Expanded(
              child: _Stat(
                  label: 'Points Earned',
                  value: '${completed * 50}')),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      children: [
        Text(
          value,
          style: BBTypography.textTheme.headlineSmall?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: BBTypography.textTheme.labelSmall
              ?.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _ApplyCodeSection extends ConsumerStatefulWidget {
  const _ApplyCodeSection({required this.onApplied});
  final VoidCallback onApplied;

  @override
  ConsumerState<_ApplyCodeSection> createState() => _ApplyCodeSectionState();
}

class _ApplyCodeSectionState extends ConsumerState<_ApplyCodeSection> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter referral code',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          const SizedBox(width: BBSpacing.sm),
          BBButton(
            label: _loading ? 'Applying...' : 'Apply',
            small: true,
            expand: false,
            onPressed: _loading ? null : _apply,
          ),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.post(ApiEndpoints.referralApply, body: {'code': code});
      _controller.clear();
      widget.onApplied();
      if (mounted) showBBSnackbar(context, message: 'Referral code applied!', isSuccess: true);
    } catch (e) {
      if (mounted) showBBSnackbar(context, message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ReferralItem extends StatelessWidget {
  const _ReferralItem({required this.referral});
  final Map<String, dynamic> referral;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final status = referral['status'] as String? ?? 'PENDING';
    final isCompleted = status == 'COMPLETED';
    final date = referral['createdAt'] != null
        ? DateTime.tryParse(referral['createdAt'] as String)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: BBSpacing.sm),
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? AppIcons.checkCircleFill : AppIcons.pending,
            color: isCompleted ? BBColors.success : colors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Text(
              isCompleted ? 'Referral completed' : 'Awaiting first booking',
              style: BBTypography.textTheme.bodyMedium
                  ?.copyWith(color: colors.text),
            ),
          ),
          if (date != null)
            Text(
              '${date.day}/${date.month}',
              style: BBTypography.textTheme.labelSmall
                  ?.copyWith(color: colors.textTertiary),
            ),
        ],
      ),
    );
  }
}
