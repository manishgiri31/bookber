import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart' show showBBSnackbar;
import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/providers.dart';
import 'wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletProvider);
    final colors = context.bbColors;

    if (state.isLoading) return const BBSkeletonWallet();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: () => ref.read(walletProvider.notifier).loadWallet(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(walletProvider.notifier).loadWallet(),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpacing.pageHorizontal,
            vertical: BBSpacing.pageVertical,
          ),
          children: [
            _BalanceCard(balance: state.balance),
            const SizedBox(height: BBSpacing.lg),
            BBButton(
              label: 'Top Up Wallet',
              icon: AppIcons.add,
              onPressed: () => _showTopUpDialog(context, ref),
            ),
            const SizedBox(height: BBSpacing.xl),
            Text(
              'TRANSACTION HISTORY',
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: BBSpacing.sm),
            if (state.transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: BBSpacing.xl),
                  child: Text(
                    'No transactions yet',
                    style: BBTypography.textTheme.bodyMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ),
              )
            else
              ...state.transactions.map((tx) => _TransactionCard(tx: tx)),
          ],
        ),
      ),
    );
  }

  Future<void> _showTopUpDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            prefixText: '₹',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              Navigator.pop(ctx, v);
            },
            child: const Text('Top Up'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0 && context.mounted) {
      try {
        final client = ref.read(apiClientProvider);
        await client.post(ApiEndpoints.walletTopUp,
            body: {
              'amount': amount,
              'refId': 'manual_${DateTime.now().millisecondsSinceEpoch}',
            });
        await ref.read(walletProvider.notifier).loadWallet();
        if (context.mounted) {
          showBBSnackbar(context, message: 'Wallet topped up by ₹${amount.toStringAsFixed(0)}', isSuccess: true);
        }
      } catch (e) {
        if (context.mounted) {
          showBBSnackbar(context, message: e.toString(), isError: true);
        }
      }
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.bbColors.accent, context.bbColors.accent.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(BBRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Balance',
            style: BBTypography.textTheme.labelMedium?.copyWith(
              color: colors.background.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: BBTypography.textTheme.displaySmall?.copyWith(
              color: colors.background,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isCredit = tx['type'] == 'CREDIT';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isCredit ? BBColors.success : BBColors.error)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? AppIcons.arrowDownLarge : AppIcons.arrowUpLarge,
              size: 18,
              color: isCredit ? BBColors.success : BBColors.error,
            ),
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
            '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
            style: BBTypography.textTheme.titleMedium?.copyWith(
              color: isCredit ? BBColors.success : BBColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
