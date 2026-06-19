import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../payment/providers/payment_providers.dart';

class QuickTagsWidget extends ConsumerWidget {
  const QuickTagsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final formState = ref.watch(reviewFormProvider);
    final rating = formState.rating;

    if (rating == 0) {
      return const SizedBox.shrink();
    }

    final isPositiveRating = rating >= 4;
    final tags = isPositiveRating
        ? ['Great Cut', 'Friendly', 'On Time', 'Clean Shop', 'Will Return']
        : ['Too Long Wait', 'Not What I Expected', 'Poor Communication', 'Rushed'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPositiveRating ? 'What did you like?' : 'What went wrong?',
          style: BBTypography.labelL.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: BBSpacing.px12),
        Wrap(
          spacing: BBSpacing.px8,
          runSpacing: BBSpacing.px8,
          children: tags.map((tag) {
            final isSelected = formState.tags.contains(tag);
            return GestureDetector(
              onTap: () => ref.read(reviewFormProvider.notifier).toggleTag(tag),
              child: AnimatedContainer(
                duration: BBMotion.fast,
                padding: const EdgeInsets.symmetric(
                    horizontal: BBSpacing.px16, vertical: BBSpacing.px10),
                decoration: BoxDecoration(
                  color: isSelected ? BBColors.brandPrimaryDim : colors.bgSurface,
                  borderRadius: BBRadius.pill,
                  border: Border.all(
                    color: isSelected ? BBColors.brandPrimary : colors.borderSubtle,
                  ),
                ),
                child: Text(
                  tag,
                  style: BBTypography.labelS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isSelected ? BBColors.brandPrimary : colors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
