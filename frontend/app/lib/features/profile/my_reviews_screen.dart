import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgCanvas,
        title: Text(
          'My Reviews',
          style: BBTypography.headingL.copyWith(color: colors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: BBIconSize.md, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border_rounded,
                size: 64, color: colors.textDisabled),
            const SizedBox(height: BBSpacing.px16),
            Text(
              'No reviews yet',
              style: BBTypography.headingM.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: BBSpacing.px8),
            Text(
              'Your reviews will appear here\nafter completing a booking.',
              textAlign: TextAlign.center,
              style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
