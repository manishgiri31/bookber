import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_empty_state.dart';
import '../../../core/widgets/bb_loading.dart';

class _MyReview {
  const _MyReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.shopName,
  });
  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String shopName;

  factory _MyReview.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;
    final booking = json['booking'] as Map<String, dynamic>?;
    final bookingShop = booking?['shop'] as Map<String, dynamic>?;
    return _MyReview(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as int?) ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      shopName: shop?['name']?.toString() ??
          bookingShop?['name']?.toString() ??
          'Barber Shop',
    );
  }
}

final _myReviewsProvider =
    FutureProvider.autoDispose<List<_MyReview>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final data =
        await api.get<Map<String, dynamic>>(ApiEndpoints.myReviews);
    final list = data['reviews'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_MyReview.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
});

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final async = ref.watch(_myReviewsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('My Reviews')),
      body: async.when(
        loading: () => const BBSkeletonListView(itemCount: 3),
        error: (_, _) => const BBEmptyState(
          title: 'Couldn\'t load reviews',
          subtitle: 'Pull down to retry.',
          icon: AppIcons.star,
        ),
        data: (reviews) => reviews.isEmpty
            ? const BBEmptyState(
                title: 'No reviews yet',
                subtitle:
                    'After your next haircut, leave a review to help others.',
                icon: AppIcons.star,
              )
            : RefreshIndicator(
                color: BBColors.amber,
                onRefresh: () => ref.refresh(_myReviewsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: BBSpacing.sm),
                  itemBuilder: (ctx, i) =>
                      _ReviewCard(review: reviews[i]),
                ),
              ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final _MyReview review;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.shopName,
                  style: BBTypography.textTheme.titleMedium
                      ?.copyWith(color: colors.text),
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(review.createdAt),
                style: BBTypography.textTheme.labelSmall
                    ?.copyWith(color: colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.xs),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating
                    ? AppIcons.starFill
                    : AppIcons.star,
                size: 16,
                color: BBColors.amber,
              ),
            ),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: BBSpacing.sm),
            Text(
              review.comment,
              style: BBTypography.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
