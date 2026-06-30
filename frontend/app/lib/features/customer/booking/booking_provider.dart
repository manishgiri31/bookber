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
    this.selectedService,
    this.selectedBarberId,
    this.selectedBarberName,
    this.joinQueue = false,
    this.scheduledStart,
    this.notes,
    this.referenceImageUrls = const [],
  });

  final String shopId;
  final String shopName;
  final ServiceItem? selectedService;
  final String? selectedBarberId;
  final String? selectedBarberName;
  final bool joinQueue;
  /// When set, booking is SCHEDULED for this time instead of joining queue now.
  final DateTime? scheduledStart;
  final String? notes;
  final List<String> referenceImageUrls;

  bool get isScheduled =>
      scheduledStart != null &&
      scheduledStart!.isAfter(DateTime.now().add(const Duration(minutes: 15)));

  double get totalAmount => selectedService?.price ?? 0;
  int get totalDuration => selectedService?.durationMin ?? 0;

  BookingFormData copyWith({
    ServiceItem? selectedService,
    bool clearService = false,
    String? selectedBarberId,
    String? selectedBarberName,
    bool? joinQueue,
    bool clearBarber = false,
    DateTime? scheduledStart,
    bool clearSchedule = false,
    String? notes,
    List<String>? referenceImageUrls,
  }) =>
      BookingFormData(
        shopId: shopId,
        shopName: shopName,
        selectedService:
            clearService ? null : (selectedService ?? this.selectedService),
        selectedBarberId:
            clearBarber ? null : (selectedBarberId ?? this.selectedBarberId),
        selectedBarberName: clearBarber
            ? null
            : (selectedBarberName ?? this.selectedBarberName),
        joinQueue: joinQueue ?? this.joinQueue,
        scheduledStart:
            clearSchedule ? null : (scheduledStart ?? this.scheduledStart),
        notes: notes ?? this.notes,
        referenceImageUrls: referenceImageUrls ?? this.referenceImageUrls,
      );

  bool get canSubmit => selectedService != null;
}

// ─────────────── Booking form notifier ───────────────

class BookingFormNotifier extends StateNotifier<BookingFormData> {
  BookingFormNotifier({required String shopId, required String shopName})
      : super(BookingFormData(shopId: shopId, shopName: shopName));

  void selectService(ServiceItem service) {
    // Single-select: selecting same service deselects, selecting different one replaces
    if (state.selectedService?.id == service.id) {
      state = state.copyWith(clearService: true);
    } else {
      state = state.copyWith(selectedService: service);
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

  void setScheduledStart(DateTime? dt) {
    if (dt == null) {
      state = state.copyWith(clearSchedule: true);
    } else {
      state = state.copyWith(scheduledStart: dt);
    }
  }

  void setNotes(String? notes) => state = state.copyWith(notes: notes);

  void addReferenceImageUrl(String url) {
    if (url.isEmpty || state.referenceImageUrls.contains(url)) return;
    state = state.copyWith(
      referenceImageUrls: [...state.referenceImageUrls, url],
    );
  }

  void removeReferenceImageUrl(String url) {
    state = state.copyWith(
      referenceImageUrls:
          state.referenceImageUrls.where((u) => u != url).toList(),
    );
  }
}

final bookingFormFamily = StateNotifierProvider.autoDispose
    .family<BookingFormNotifier, BookingFormData,
        ({String shopId, String shopName})>(
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
    StateNotifierProvider<BookingSubmitNotifier, BookingSubmitState>(
  (ref) => BookingSubmitNotifier(ref),
);

class BookingSubmitNotifier extends StateNotifier<BookingSubmitState> {
  BookingSubmitNotifier(this._ref) : super(BookingIdle());

  final Ref _ref;

  Future<Booking?> submit(BookingFormData form) async {
    if (form.selectedService == null) return null;
    state = BookingSubmitting();
    try {
      final api = _ref.read(apiClientProvider);

      // POST /bookings calls reserveQueue. Scheduled bookings get SCHEDULED status;
      // immediate bookings (joinQueue=true) become QUEUED walk-ins.
      final body = {
        'shopId': form.shopId,
        'serviceId': form.selectedService!.id,
        if (form.selectedBarberId != null) 'barberId': form.selectedBarberId,
        'walkIn': form.joinQueue && !form.isScheduled,
        if (form.isScheduled)
          'scheduledStart': form.scheduledStart!.toUtc().toIso8601String(),
        if (form.notes != null && form.notes!.isNotEmpty) 'notes': form.notes,
        if (form.referenceImageUrls.isNotEmpty)
          'referenceImageUrls': form.referenceImageUrls,
      };

      final data = await api.post<Map<String, dynamic>>(
        ApiEndpoints.bookings,
        body: body,
      );

      final booking = Booking.fromJson(
        data['booking'] as Map<String, dynamic>? ?? data,
      );

      state = BookingSuccess(booking);
      return booking;
    } catch (e) {
      state = BookingFailed(e.toString().replaceFirst('Exception: ', ''));
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
