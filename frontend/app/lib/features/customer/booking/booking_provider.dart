import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/providers.dart';
import '../../shared/domain/booking_models.dart';
import '../../shared/domain/shop_models.dart';

// ─────────────── Booking form state ───────────────

class BookingFormData {
  const BookingFormData({
    required this.shopId,
    required this.shopName,
    this.selectedServices = const [],
    this.selectedBarberId,
    this.selectedBarberName,
    this.joinQueue = false,
  });

  final String shopId;
  final String shopName;
  final List<ServiceItem> selectedServices;
  final String? selectedBarberId;
  final String? selectedBarberName;
  final bool joinQueue;

  double get totalAmount =>
      selectedServices.fold(0, (s, e) => s + e.price);
  int get totalDuration =>
      selectedServices.fold(0, (s, e) => s + e.durationMin);

  BookingFormData copyWith({
    List<ServiceItem>? selectedServices,
    String? selectedBarberId,
    String? selectedBarberName,
    bool? joinQueue,
    bool clearBarber = false,
  }) =>
      BookingFormData(
        shopId: shopId,
        shopName: shopName,
        selectedServices: selectedServices ?? this.selectedServices,
        selectedBarberId:
            clearBarber ? null : (selectedBarberId ?? this.selectedBarberId),
        selectedBarberName: clearBarber
            ? null
            : (selectedBarberName ?? this.selectedBarberName),
        joinQueue: joinQueue ?? this.joinQueue,
      );

  bool get canSubmit => selectedServices.isNotEmpty;
}

// ─────────────── Booking form notifier ───────────────

class BookingFormNotifier extends StateNotifier<BookingFormData> {
  BookingFormNotifier({required String shopId, required String shopName})
      : super(BookingFormData(shopId: shopId, shopName: shopName));

  void toggleService(ServiceItem service) {
    final current = state.selectedServices;
    if (current.any((s) => s.id == service.id)) {
      state = state.copyWith(
        selectedServices: current.where((s) => s.id != service.id).toList(),
      );
    } else {
      state = state.copyWith(selectedServices: [...current, service]);
    }
  }

  void selectBarber(String? barberId, String? barberName) {
    if (barberId == null) {
      state = state.copyWith(clearBarber: true);
    } else {
      state = state.copyWith(
        selectedBarberId: barberId,
        selectedBarberName: barberName,
      );
    }
  }

  void setJoinQueue(bool v) => state = state.copyWith(joinQueue: v);
}

final bookingFormFamily = StateNotifierProvider.autoDispose
    .family<BookingFormNotifier, BookingFormData, ({String shopId, String shopName})>(
  (ref, arg) =>
      BookingFormNotifier(shopId: arg.shopId, shopName: arg.shopName),
);

// ─────────────── Submit booking ───────────────

sealed class BookingSubmitState {}

class BookingIdle extends BookingSubmitState {}

class BookingSubmitting extends BookingSubmitState {}

class BookingSuccess extends BookingSubmitState {
  BookingSuccess(this.booking);
  final Booking booking;
}

class BookingFailed extends BookingSubmitState {
  BookingFailed(this.message);
  final String message;
}

final bookingSubmitProvider =
    StateNotifierProvider.autoDispose<BookingSubmitNotifier, BookingSubmitState>(
  (ref) => BookingSubmitNotifier(ref),
);

class BookingSubmitNotifier extends StateNotifier<BookingSubmitState> {
  BookingSubmitNotifier(this._ref) : super(BookingIdle());

  final Ref _ref;

  Future<Booking?> submit(BookingFormData form) async {
    state = BookingSubmitting();
    try {
      final api = _ref.read(apiClientProvider);

      final Map<String, dynamic> body;
      if (form.joinQueue) {
        body = {
          'shopId': form.shopId,
          'serviceIds': form.selectedServices.map((s) => s.id).toList(),
          if (form.selectedBarberId != null) 'barberId': form.selectedBarberId,
          'walkIn': false,
        };
      } else {
        body = {
          'shopId': form.shopId,
          'serviceIds': form.selectedServices.map((s) => s.id).toList(),
          if (form.selectedBarberId != null) 'barberId': form.selectedBarberId,
        };
      }

      final data = await api.post<Map<String, dynamic>>(
        ApiEndpoints.bookings,
        body: body,
      );

      final booking = Booking.fromJson(
        data['booking'] as Map<String, dynamic>? ?? data,
      );

      if (form.joinQueue) {
        await _ref.read(apiClientProvider).post<void>(
          ApiEndpoints.enqueue(form.shopId),
          body: {'bookingId': booking.id},
        );
      }

      state = BookingSuccess(booking);
      return booking;
    } catch (e) {
      state = BookingFailed(e.toString());
      return null;
    }
  }

  void reset() => state = BookingIdle();
}

// ─────────────── My bookings ───────────────

final myBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final data = await api.get<Map<String, dynamic>>('/bookings/my');
    final list = data['bookings'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Booking.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
});
