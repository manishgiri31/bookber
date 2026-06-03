import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../payment/providers/payment_providers.dart';

class QuickTagsWidget extends ConsumerWidget {
  const QuickTagsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(reviewFormProvider);
    final rating = formState.rating;

    // Show tags only if rating is selected
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BookBerPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = formState.tags.contains(tag);
            return GestureDetector(
              onTap: () => ref.read(reviewFormProvider.notifier).toggleTag(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? BookBerPalette.primaryAccent.withValues(alpha: 0.12)
                      : BookBerPalette.bgSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? BookBerPalette.primaryAccent
                        : const Color(0x0FFFFFFF),
                    width: 1,
                  ),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? BookBerPalette.primaryAccent
                        : BookBerPalette.textSecondary,
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
