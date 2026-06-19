import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import 'providers/booking_form_provider.dart';
import 'steps/select_service_step.dart';
import 'steps/select_barber_step.dart';
import 'steps/select_time_step.dart';
import 'steps/confirm_booking_step.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key, required this.shopId, required this.shopName});

  final String shopId;
  final String shopName;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize booking form with shop info
    ref.read(bookingFormProvider.notifier).initBooking(widget.shopId, widget.shopName);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final formState = ref.watch(bookingFormProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgCanvas,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Book Appointment',
          style: BBTypography.headingM.copyWith(color: colors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCurrentStep(formState.currentStep),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(int currentStep) {
    switch (currentStep) {
      case 1:
        return const SelectServiceStep();
      case 2:
        return const SelectBarberStep();
      case 3:
        return const SelectTimeStep();
      case 4:
        return const ConfirmBookingStep();
      default:
        return const SelectServiceStep();
    }
  }
}
