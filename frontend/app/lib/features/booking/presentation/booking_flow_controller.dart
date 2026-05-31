import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../data/booking_repository.dart';
import '../domain/booking_flow_state.dart';

class BookingFlowController extends Notifier<BookingFlowState> {
  @override
  BookingFlowState build() {
    return const BookingFlowState();
  }

  void selectBarber(Barber barber) {
    state = state.copyWith(
      selectedBarber: barber,
      selectedServices: const [],
      selectedTimeSlot: null,
      booking: null,
    );
    Future.microtask(loadServices);
  }

  Future<void> loadServices() async {
    final barber = state.selectedBarber;
    if (barber == null) return;
    state = state.copyWith(isLoadingServices: true, errorMessage: null);
    final result = await ref
        .read(bookingRepositoryProvider)
        .fetchServices(barber.id);
    if (result is ApiSuccess<List<ServiceItem>>) {
      state = state.copyWith(
        isLoadingServices: false,
        availableServices: result.data,
      );
    } else if (result is ApiFailure<List<ServiceItem>>) {
      state = state.copyWith(
        isLoadingServices: false,
        errorMessage: result.message,
      );
    }
  }

  void toggleService(ServiceItem service) {
    final items = [...state.selectedServices];
    if (items.any((item) => item.id == service.id)) {
      items.removeWhere((item) => item.id == service.id);
    } else {
      items.add(service);
    }
    state = state.copyWith(selectedServices: items);
  }

  void selectTimeSlot(DateTime timeSlot) {
    state = state.copyWith(selectedTimeSlot: timeSlot);
  }

  int estimateServiceDuration() {
    return state.selectedServices.fold<int>(
      0,
      (sum, item) => sum + item.durationMin,
    );
  }

  List<DateTime> get availableTimeSlots {
    final now = DateTime.now();
    return List.generate(
      5,
      (index) => now.add(Duration(minutes: 10 + index * 15)),
    );
  }

  Future<void> createBooking() async {
    final barber = state.selectedBarber;
    if (barber == null || state.selectedServices.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Select a barber and at least one service.',
      );
      return;
    }

    final repo = ref.read(bookingRepositoryProvider);
    state = state.copyWith(isBooking: true, optimisticStatus: 'CONFIRMING');
    final result = await repo.createBooking(
      barberId: barber.id,
      barberName: barber.name,
      services: state.selectedServices,
      scheduledAt: state.selectedTimeSlot,
    );

    if (result is ApiSuccess<Booking>) {
      state = state.copyWith(
        isBooking: false,
        booking: result.data,
        optimisticStatus: 'CONFIRMED',
      );
    } else if (result is ApiFailure<Booking>) {
      state = state.copyWith(
        isBooking: false,
        optimisticStatus: null,
        errorMessage: result.message,
      );
    }
  }
}

final bookingFlowControllerProvider =
    NotifierProvider<BookingFlowController, BookingFlowState>(
      BookingFlowController.new,
    );
