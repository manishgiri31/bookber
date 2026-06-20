import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/bb_colors.dart';
import '../../core/design/bb_tokens.dart';
import '../../core/design/bb_typography.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/bb_loading.dart';
import '../auth/data/auth_provider.dart';
import '../shared/domain/shop_models.dart';

final adminShopsProvider = FutureProvider.autoDispose<List<Shop>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>('/shops');
  final list = data['shops'] as List? ?? [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(Shop.fromJson)
      .toList();
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final user = ref.watch(currentUserProvider);
    final shopsAsync = ref.watch(adminShopsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BBSpacing.pageHorizontal,
                  BBSpacing.lg,
                  BBSpacing.pageHorizontal,
                  BBSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Panel',
                            style: BBTypography.textTheme.displaySmall
                                ?.copyWith(color: colors.text),
                          ),
                          Text(
                            user?.email ?? '',
                            style: BBTypography.textTheme.bodyMedium
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () =>
                          ref.read(authProvider.notifier).logout(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: BBSpacing.pageHorizontal),
                child: Text(
                  'All Shops',
                  style: BBTypography.textTheme.headlineSmall
                      ?.copyWith(color: colors.text),
                ),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: BBSpacing.md)),
            shopsAsync.when(
              loading: () =>
                  const SliverFillRemaining(child: Center(child: BBLoader())),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text(e.toString())),
              ),
              data: (shops) => SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: BBSpacing.pageHorizontal),
                sliver: SliverList.separated(
                  itemCount: shops.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: BBSpacing.sm),
                  itemBuilder: (ctx, i) => _AdminShopTile(shop: shops[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: BBSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

class _AdminShopTile extends StatelessWidget {
  const _AdminShopTile({required this.shop});
  final Shop shop;

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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BBRadius.md),
            ),
            child: Icon(
              Icons.store_outlined,
              size: 22,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: BBTypography.textTheme.titleMedium
                      ?.copyWith(color: colors.text),
                ),
                Text(
                  '${shop.city} · ${shop.rating.toStringAsFixed(1)}★',
                  style: BBTypography.textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: shop.isOpen
                  ? BBColors.success.withValues(alpha: 0.12)
                  : BBColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(BBRadius.full),
            ),
            child: Text(
              shop.isOpen ? 'Open' : 'Closed',
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: shop.isOpen ? BBColors.success : BBColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
