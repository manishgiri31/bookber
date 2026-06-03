import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../customer/providers/shop_providers.dart';
import '../data/booking_repository.dart';

class BookingFormState {
  const BookingFormState({
    this.shopId = '',
    this.shopName = '',
    this.selectedServices = const <ShopService>[],
    this.selectedBarberId,
    this.anyBarber = false,
    this.selectedDate,
    this.selectedSlot,
    this.paymentMethod = 'pay_at_shop',
    this.currentStep = 1,
    this.totalSteps = 4,
    this.isJoinQueue = false,
  });

  final String shopId;
  final String shopName;
  final List<ShopService> selectedServices;
  final String? selectedBarberId;
  final bool anyBarber;
  final DateTime? selectedDate;
  final TimeSlot? selectedSlot;
  final String paymentMethod;
  final int currentStep;
  final int totalSteps;
  final bool isJoinQueue;

  BookingFormState copyWith({
    String? shopId,
    String? shopName,
    List<ShopService>? selectedServices,
    String? selectedBarberId,
    bool? anyBarber,
    DateTime? selectedDate,
    TimeSlot? selectedSlot,
    String? paymentMethod,
    int? currentStep,
    int? totalSteps,
    bool? isJoinQueue,
  }) {
    return BookingFormState(
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      selectedServices: selectedServices ?? this.selectedServices,
      selectedBarberId: selectedBarberId ?? this.selectedBarberId,
      anyBarber: anyBarber ?? this.anyBarber,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isJoinQueue: isJoinQueue ?? this.isJoinQueue,
    );
  }

  int get totalDuration {
    return selectedServices.fold<int>(0, (sum, item) => sum + item.durationMin);
  }

  double get totalAmount {
    return selectedServices.fold<double>(0.0, (sum, item) => sum + item.price);
  }

  double get discountAmount {
    return selectedServices.length > 1 ? 50.0 : 0.0;
  }

  List<String> get selectedServiceIds =>
      selectedServices.map((service) => service.id).toList();
  double get totalPrice => totalAmount - discountAmount;

  String? get barberId => selectedBarberId;
  List<String> get serviceIds => selectedServiceIds;
  TimeSlot? get selectedTimeSlot => selectedSlot;
  bool get isQueueMode => isJoinQueue;
}

class BookingFormNotifier extends StateNotifier<BookingFormState> {
  BookingFormNotifier() : super(const BookingFormState());

  void initBooking(String shopId, String shopName) {
    state = state.copyWith(shopId: shopId, shopName: shopName, currentStep: 1);
  }

  void toggleService(ShopService service) {
    final services = [...state.selectedServices];
    final index = services.indexWhere((item) => item.id == service.id);
    if (index >= 0) {
      services.removeAt(index);
    } else {
      services.add(service);
    }
    state = state.copyWith(selectedServices: services);
  }

  void selectBarber(String barberId) {
    state = state.copyWith(selectedBarberId: barberId, anyBarber: false);
  }

  void selectAnyBarber() {
    state = state.copyWith(selectedBarberId: null, anyBarber: true);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, selectedSlot: null);
  }

  void selectSlot(TimeSlot slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  void selectTimeSlot(String time) {
    state = state.copyWith(selectedSlot: TimeSlot(time: time, isAvailable: true));
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setQueueMode(bool shouldJoinQueue) {
    state = state.copyWith(isJoinQueue: shouldJoinQueue);
  }

  void toggleJoinQueue() {
    state = state.copyWith(isJoinQueue: !state.isJoinQueue);
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void reset() {
    state = const BookingFormState();
  }
}

final bookingFormProvider =
    StateNotifierProvider<BookingFormNotifier, BookingFormState>(
  (ref) => BookingFormNotifier(),
);

final availableSlotsProvider =
    FutureProvider.family<List<TimeSlot>, ({String barberId, DateTime date, int duration})>(
  (ref, params) async {
    if (params.barberId.isEmpty) {
      return const <TimeSlot>[];
    }

    final result = await ref.read(bookingRepositoryProvider).getAvailableSlots(
          params.barberId,
          params.date,
          params.duration,
        );

    return result is ApiSuccess<List<TimeSlot>> ? result.data : const <TimeSlot>[];
  },
);

final availableServicesProvider = shopServicesProvider;
final availableBarbersProvider = shopBarbersProvider;
