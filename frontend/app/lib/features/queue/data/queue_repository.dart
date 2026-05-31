import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';

class QueueRepository {
  const QueueRepository();

  Future<ApiResult<QueueStateModel>> fetchQueue(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiSuccess(
      QueueStateModel(
        bookingId: bookingId,
        position: 3,
        etaMinutes: 28,
        status: 'WAITING',
        chairLabel: 'Chair 2',
      ),
    );
  }
}

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  return const QueueRepository();
});
