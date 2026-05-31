import '../../../core/models/bookber_models.dart';

class BookingFlowState {
  const BookingFlowState({
    this.selectedBarber,
    this.availableServices = const [],
    this.selectedServices = const [],
    this.selectedTimeSlot,
    this.isLoadingServices = false,
    this.isBooking = false,
    this.errorMessage,
    this.optimisticStatus,
    this.booking,
  });

  final Barber? selectedBarber;
  final List<ServiceItem> availableServices;
  final List<ServiceItem> selectedServices;
  final DateTime? selectedTimeSlot;
  final bool isLoadingServices;
  final bool isBooking;
  final String? errorMessage;
  final String? optimisticStatus;
  final Booking? booking;

  BookingFlowState copyWith({
    Barber? selectedBarber,
    List<ServiceItem>? availableServices,
    List<ServiceItem>? selectedServices,
    DateTime? selectedTimeSlot,
    bool? isLoadingServices,
    bool? isBooking,
    String? errorMessage,
    String? optimisticStatus,
    Booking? booking,
  }) {
    return BookingFlowState(
      selectedBarber: selectedBarber ?? this.selectedBarber,
      availableServices: availableServices ?? this.availableServices,
      selectedServices: selectedServices ?? this.selectedServices,
      selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
      isLoadingServices: isLoadingServices ?? this.isLoadingServices,
      isBooking: isBooking ?? this.isBooking,
      errorMessage: errorMessage,
      optimisticStatus: optimisticStatus ?? this.optimisticStatus,
      booking: booking ?? this.booking,
    );
  }
}
