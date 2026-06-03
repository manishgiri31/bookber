import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../data/queue_repository.dart';

class QueueController extends AsyncNotifier<QueueStateModel> {
  @override
  Future<QueueStateModel> build() async {
    return QueueStateModel(
      bookingId: '',
      position: 0,
      etaMinutes: 0,
      status: 'WAITING',
      chairLabel: '',
    );
  }

  Future<void> loadQueue(String bookingId) async {
    state = const AsyncLoading();
    final result = await ref.read(queueRepositoryProvider).fetchQueue(bookingId);
    state = AsyncData(result is ApiSuccess<QueueStateModel>
        ? result.data
        : QueueStateModel(
            bookingId: bookingId,
            position: 0,
            etaMinutes: 0,
            status: 'WAITING',
            chairLabel: '',
          ));
  }

  void applySocketUpdate(QueueStateModel model) {
    state = AsyncData(model);
  }
}

final queueControllerProvider =
    AsyncNotifierProvider<QueueController, QueueStateModel>(QueueController.new);
