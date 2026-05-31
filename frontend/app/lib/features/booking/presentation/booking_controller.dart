import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../data/booking_repository.dart';

class BookingController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final result = await ref.read(bookingRepositoryProvider).fetchHistory();
    return result is ApiSuccess<List<Booking>> ? result.data : const [];
  }

  Future<void> refreshHistory() async {
    state = const AsyncLoading();
    final result = await ref.read(bookingRepositoryProvider).fetchHistory();
    state = AsyncData(result is ApiSuccess<List<Booking>> ? result.data : const []);
  }
}

final bookingControllerProvider =
    AsyncNotifierProvider<BookingController, List<Booking>>(BookingController.new);
