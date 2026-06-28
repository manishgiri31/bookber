import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart';

final _loyaltyProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.read(apiClientProvider);
  final results = await Future.wait<dynamic>([
    client.get<dynamic>(ApiEndpoints.loyaltyAccount),
    client.get<dynamic>(ApiEndpoints.loyaltyTransactions),
  ]);
  final account = results[0] is Map<String, dynamic>
      ? results[0] as Map<String, dynamic>
      : <String, dynamic>{};
  final txRes = results[1] is Map<String, dynamic>
      ? results[1] as Map<String, dynamic>
      : <String, dynamic>{};
  return {
    'account': account,
    'transactions': (txRes['transactions'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ?? [],
  };
});

const _tierColors = {
  'BRONZE': Color(0xFFCD7F32),
  'SILVER': Color(0xFFC0C0C0),
  'GOLD': Color(0xFFFFD700),
  'PLATINUM': Color(0xFFE5E4E2),
  'DIAMOND': Color(0xFF67E8F9),
};

const _tierThresholds = {
  'BRONZE': 0,
  'SILVER': 500,
  'GOLD': 1500,
  'PLATINUM': 3000,
  'DIAMOND': 6000,
};

const _tierBenefits = {
  'BRONZE': ['Earn 10 pts per ₹100', 'Birthday bonus', 'Basic support'],
  'SILVER': ['Earn 12 pts per ₹100', '5% discount on services', 'Priority queue', 'Birthday bonus (2×)'],
  'GOLD': ['Earn 15 pts per ₹100', '10% discount on services', 'Skip queue once/month', 'Exclusive offers', 'Free haircut on birthday'],
  'PLATINUM': ['Earn 20 pts per ₹100', '15% discount on services', 'Skip queue 3×/month', 'VIP booking slot', 'Concierge support'],
  'DIAMOND': ['Earn 25 pts per ₹100', '20% discount on services', 'Skip queue unlimited', 'Personal stylist', 'Exclusive Diamond events', 'Free monthly haircut'],
};

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_loyaltyProvider);
    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Loyalty Points')),
      body: async.when(
        loading: () => const BBLoadingScreen(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (data) {
          final account = data['account'] as Map<String, dynamic>;
          final transactions =
              data['transactions'] as List<Map<String, dynamic>>;
          final points = account['points'] as int? ?? 0;
          final tier = account['tier'] as String? ?? 'BRONZE';
          final tierColor = _tierColors[tier] ?? BBColors.amber;
          final nextTierThreshold = _nextThreshold(tier);
          final progress = nextTierThreshold != null
              ? (points / nextTierThreshold).clamp(0.0, 1.0)
              : 1.0;

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.pageHorizontal,
              vertical: BBSpacing.pageVertical,
            ),
            children: [
              _TierCard(
                  points: points,
                  tier: tier,
                  tierColor: tierColor,
                  progress: progress,
                  nextThreshold: nextTierThreshold),
              const SizedBox(height: BBSpacing.base),
              _RedeemCard(points: points, ref: ref),
              const SizedBox(height: BBSpacing.xl),
              _TierBenefitsCard(tier: tier, tierColor: tierColor),
              const SizedBox(height: BBSpacing.xl),
              _AllTiersProgress(currentTier: tier),
              const SizedBox(height: BBSpacing.xl),
              Text(
                'TRANSACTION HISTORY',
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: BBSpacing.sm),
              if (transactions.isEmpty)
                Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: BBSpacing.xl),
                    child: Text(
                      'Earn points by completing bookings!',
                      style: BBTypography.textTheme.bodyMedium
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ),
                )
              else
                ...transactions.map((tx) => _LoyaltyTxCard(tx: tx)),
            ],
          );
        },
      ),
    );
  }

  int? _nextThreshold(String tier) {
    const order = ['BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'DIAMOND'];
    final idx = order.indexOf(tier);
    if (idx < 0 || idx >= order.length - 1) return null;
    return _tierThresholds[order[idx + 1]];
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.points,
    required this.tier,
    required this.tierColor,
    required this.progress,
    required this.nextThreshold,
  });
  final int points;
  final String tier;
  final Color tierColor;
  final double progress;
  final int? nextThreshold;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(color: tierColor.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.military_tech_rounded, color: tierColor, size: 40),
              const SizedBox(width: BBSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier,
                    style: BBTypography.textTheme.titleLarge?.copyWith(
                      color: tierColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$points pts',
                    style: BBTypography.textTheme.headlineSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (nextThreshold != null) ...[
            const SizedBox(height: BBSpacing.base),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation(tierColor),
              borderRadius: BorderRadius.circular(BBRadius.full),
              minHeight: 8,
            ),
            const SizedBox(height: BBSpacing.xs),
            Text(
              '${(nextThreshold! - points).clamp(0, nextThreshold!)} pts to next tier',
              style: BBTypography.textTheme.labelSmall
                  ?.copyWith(color: colors.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: BBSpacing.sm),
            Text(
              'You\'ve reached the highest tier!',
              style: BBTypography.textTheme.labelMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoyaltyTxCard extends StatelessWidget {
  const _LoyaltyTxCard({required this.tx});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isEarn = tx['type'] == 'EARN';
    final points = tx['points'] as int? ?? 0;
    final reason = tx['reason'] as String? ?? '';
    final date = tx['createdAt'] != null
        ? DateTime.tryParse(tx['createdAt'] as String)
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
            isEarn ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
            color: isEarn ? BBColors.success : BBColors.error,
            size: 22,
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason,
                    style: BBTypography.textTheme.bodyMedium
                        ?.copyWith(color: colors.text)),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: BBTypography.textTheme.labelSmall
                        ?.copyWith(color: colors.textTertiary),
                  ),
              ],
            ),
          ),
          Text(
            '${isEarn ? '+' : '-'}$points pts',
            style: BBTypography.textTheme.titleSmall?.copyWith(
              color: isEarn ? BBColors.success : BBColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Redeem card ────────────────────────────────────────────────────────────────

class _RedeemCard extends StatelessWidget {
  const _RedeemCard({required this.points, required this.ref});
  final int points;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final canRedeem = points >= 100;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: canRedeem
                  ? BBColors.amber.withValues(alpha: 0.12)
                  : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BBRadius.md),
            ),
            child: Icon(
              Icons.redeem_rounded,
              color: canRedeem ? BBColors.amber : colors.textTertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redeem Points',
                  style: BBTypography.textTheme.titleSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  canRedeem
                      ? '100 pts = ₹10 off your next booking'
                      : 'Earn ${100 - points} more pts to redeem',
                  style: BBTypography.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (canRedeem)
            GestureDetector(
              onTap: () => _redeem(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: BBColors.amber,
                  borderRadius: BorderRadius.circular(BBRadius.full),
                ),
                child: Text(
                  'Redeem',
                  style: BBTypography.textTheme.labelMedium?.copyWith(
                    color: colors.background,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _redeem(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem Points'),
        content: const Text(
            'Redeem 100 points for ₹10 off your next booking? Points will be deducted immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.post<void>(ApiEndpoints.loyaltyRedeem, body: {'points': 100});
      if (context.mounted) {
        showBBSnackbar(context,
            message: '100 pts redeemed! ₹10 will apply to your next booking.',
            isSuccess: true);
      }
    } catch (e) {
      if (context.mounted) {
        showBBSnackbar(context, message: e.toString(), isError: true);
      }
    }
  }
}

// ── Tier benefits ──────────────────────────────────────────────────────────────

class _TierBenefitsCard extends StatelessWidget {
  const _TierBenefitsCard({required this.tier, required this.tierColor});
  final String tier;
  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final benefits = _tierBenefits[tier] ?? [];
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: tierColor, size: 18),
              const SizedBox(width: BBSpacing.sm),
              Text(
                '$tier BENEFITS',
                style: BBTypography.textTheme.labelMedium?.copyWith(
                  color: tierColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.md),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: BBSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: tierColor, size: 16),
                    const SizedBox(width: BBSpacing.sm),
                    Expanded(
                      child: Text(
                        b,
                        style: BBTypography.textTheme.bodySmall?.copyWith(
                          color: colors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── All tiers progress ────────────────────────────────────────────────────────

class _AllTiersProgress extends StatelessWidget {
  const _AllTiersProgress({required this.currentTier});
  final String currentTier;

  static const _order = ['BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'DIAMOND'];

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final currentIdx = _order.indexOf(currentTier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALL TIERS',
          style: BBTypography.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: BBSpacing.md),
        Row(
          children: _order.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final color = _tierColors[t] ?? BBColors.amber;
            final isActive = i <= currentIdx;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    height: 6,
                    margin: EdgeInsets.only(right: i < _order.length - 1 ? 2 : 0),
                    decoration: BoxDecoration(
                      color: isActive ? color : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(BBRadius.full),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t[0] + t.substring(1, 2).toLowerCase(),
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: isActive ? color : colors.textTertiary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
