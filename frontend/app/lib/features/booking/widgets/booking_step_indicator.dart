import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';

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
    return Column(
      children: [
        Row(
          children: List.generate(_totalSteps, (index) {
            final stepNumber = index + 1;
            final isCompleted = index < _currentStep;
            final isActive = index == _currentStep;
            final isUpcoming = index > _currentStep;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Step circle
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted || isActive
                                ? BookBerPalette.primaryAccent
                                : BookBerPalette.bgElevated,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: BookBerPalette.bgPrimary,
                                  )
                                : Text(
                                    stepNumber.toString(),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? BookBerPalette.bgPrimary
                                          : BookBerPalette.textMuted,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Step label
                        Text(
                          _getStepLabel(stepNumber),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? BookBerPalette.primaryAccent
                                : BookBerPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Connector line
                  if (index < _totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? BookBerPalette.primaryAccent
                              : BookBerPalette.bgElevated,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  String _getStepLabel(int step) {
    switch (step) {
      case 1:
        return 'Service';
      case 2:
        return 'Barber';
      case 3:
        return 'Time';
      case 4:
        return 'Confirm';
      default:
        return '';
    }
  }
}
