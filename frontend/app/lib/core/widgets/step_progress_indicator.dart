import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.dart';

class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    super.key,
    required currentStep,
    required totalSteps,
  })  : _currentStep = currentStep,
        _totalSteps = totalSteps;

  final int _currentStep;
  final int _totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final progress = _currentStep / _totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $_currentStep of $_totalSteps',
          style: BBTypography.labelS.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: BBSpacing.px8),
        ClipRRect(
          borderRadius: BBRadius.pill,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: colors.bgElevated,
            color: BBColors.brandPrimary,
          ),
        ),
      ],
    );
  }
}
