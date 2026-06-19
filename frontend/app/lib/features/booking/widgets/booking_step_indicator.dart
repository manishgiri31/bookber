import 'package:flutter/material.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';

class BookingStepIndicator extends StatelessWidget {
  const BookingStepIndicator({
    super.key,
    required currentStep,
    totalSteps = 4,
  })  : _currentStep = currentStep,
        _totalSteps = totalSteps;

  final int _currentStep;
  final int _totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Row(
      children: List.generate(_totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = index < _currentStep;
        final isActive = index == _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted || isActive
                            ? BBColors.brandPrimary
                            : colors.bgElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : Text(
                                stepNumber.toString(),
                                style: BBTypography.labelM.copyWith(
                                  color: isActive ? Colors.white : colors.textDisabled,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: BBSpacing.px8),
                    Text(
                      _getStepLabel(stepNumber),
                      style: BBTypography.overline.copyWith(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? BBColors.brandPrimary : colors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < _totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: BBSpacing.px8),
                    color: isCompleted ? BBColors.brandPrimary : colors.bgElevated,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _getStepLabel(int step) => switch (step) {
        1 => 'Service',
        2 => 'Barber',
        3 => 'Time',
        4 => 'Confirm',
        _ => '',
      };
}
