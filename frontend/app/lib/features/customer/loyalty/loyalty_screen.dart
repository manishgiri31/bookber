import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_loading.dart';

final _loyaltyProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.read(apiClientProvider);
  final results = await Future.wait<dynamic>([
    client.get<dynamic>(ApiEndpoints.loyaltyAccount),
    client.get<dynamic>(ApiEndpoints.loyaltyTransactions),
  ]);
  final account = results[0] as Map<String, dynamic>;
  final txRes = results[1] as Map<String, dynamic>;
  return {
    'account': account,
    'transactions':
        (txRes['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [],
  };
});

const _tierColors = {
  'BRONZE': Color(0xFFCD7F32),
  'SILVER': Color(0xFFC0C0C0),
  'GOLD': Color(0xFFFFD700),
  'PLATINUM': Color(0xFFE5E4E2),
};

const _tierThresholds = {
  'BRONZE': 0,
  'SILVER': 500,
  'GOLD': 1500,
  'PLATINUM': 3000,
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
    const order = ['BRONZE', 'SILVER', 'GOLD', 'PLATINUM'];
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
