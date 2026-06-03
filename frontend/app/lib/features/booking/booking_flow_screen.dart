import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
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
    final formState = ref.watch(bookingFormProvider);

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      appBar: AppBar(
        backgroundColor: BookBerPalette.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: BookBerPalette.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Book Appointment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BookBerPalette.textPrimary,
          ),
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
