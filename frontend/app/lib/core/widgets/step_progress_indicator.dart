import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/design_system.dart';

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
    final progress = (_currentStep) / _totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $_currentStep of $_totalSteps',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: BookBerPalette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: BookBerPalette.bgElevated,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: progress,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: BookBerPalette.primaryAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
