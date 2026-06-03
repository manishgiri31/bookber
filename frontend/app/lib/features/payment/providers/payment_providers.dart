import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/storage/app_storage.dart';
import '../../booking/data/booking_repository.dart';

enum PaymentMethod {
  cash,
  upi,
  card,
  wallet;

  String get apiValue => name;
}

class PaymentFormState {
  const PaymentFormState({
    this.selectedMethod = PaymentMethod.cash,
  });

  final PaymentMethod selectedMethod;
  List<ServiceItem> get services => const <ServiceItem>[];
  double get subtotal => 0;
  double get discount => 0;
  double get total => subtotal - discount;

  PaymentFormState copyWith({PaymentMethod? selectedMethod}) {
    return PaymentFormState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
    );
  }
}

class PaymentFormNotifier extends StateNotifier<PaymentFormState> {
  PaymentFormNotifier() : super(const PaymentFormState());

  void selectPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedMethod: method);
  }
}

final paymentFormProvider = StateNotifierProvider<PaymentFormNotifier, PaymentFormState>((ref) {
  return PaymentFormNotifier();
});

class PaymentRepository {
  PaymentRepository(this._dioClient);

  final DioClient _dioClient;

  Future<ApiResult<Payment>> initiatePayment(String bookingId, String method) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.post(
        '/api/payments',
        body: {
          'bookingId': bookingId,
          'method': method,
        },
      );
      final paymentJson = response is Map<String, dynamic>
          ? (response['payment'] as Map<String, dynamic>?) ?? response
          : <String, dynamic>{};
      return Payment.fromJson(paymentJson);
    });
  }

  Future<ApiResult<Payment>> getPayment(String bookingId) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/api/payments/booking/$bookingId');
      final paymentJson = response is Map<String, dynamic>
          ? (response['payment'] as Map<String, dynamic>?) ?? response
          : <String, dynamic>{};
      return Payment.fromJson(paymentJson);
    });
  }

  Future<ApiResult<String>> getReceiptUrl(String paymentId) async {
    return ApiResult.guard(() async {
      final response = await _dioClient.get('/api/payments/$paymentId/receipt');
      final json = response is Map<String, dynamic> ? response : <String, dynamic>{};
      return json['receiptUrl']?.toString() ?? '';
    });
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(dioClientProvider));
});

class ReviewRepository {
  ReviewRepository(this._dioClient);

  final DioClient _dioClient;

  Future<ApiResult<void>> submitReview(ReviewFormState form) async {
    return ApiResult.guard(() async {
      await _dioClient.post(
        '/api/reviews',
        body: {
          'bookingId': form.bookingId,
          'rating': form.rating,
          'comment': form.comment,
          'tags': form.selectedTags,
        },
      );
    });
  }

  Future<ApiResult<List<String>>> uploadPhotos(List<File> photos) async {
    return ApiResult.guard(() async {
      final formData = FormData();
      for (final photo in photos) {
        formData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(photo.path),
          ),
        );
      }

      final response = await _dioClient.post('/api/reviews/photos', body: formData);
      final json = response is Map<String, dynamic> ? response : <String, dynamic>{};
      return (json['urls'] as List<dynamic>? ?? const <dynamic>[])
          .map((url) => url.toString())
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
    });
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.read(dioClientProvider));
});

class PaymentController extends AsyncNotifier<Payment?> {
  @override
  Future<Payment?> build() async => null;

  Future<void> init(String bookingId) async {
    state = const AsyncLoading();
    final result = await ref.read(paymentRepositoryProvider).getPayment(bookingId);

    switch (result) {
      case ApiSuccess<Payment>(:final data):
        state = AsyncData(data);
      case ApiError<Payment>(:final message, :final code):
        if (_isUnauthorized(code)) {
          await _redirectToLogin();
          return;
        }
        if (_isNotFound(code, message)) {
          state = const AsyncData(null);
          return;
        }
        state = AsyncError(message, StackTrace.current);
    }
  }

  Future<ApiResult<Payment>> confirmPayment(String bookingId, String method) async {
    state = const AsyncLoading();
    final result = await ref.read(paymentRepositoryProvider).initiatePayment(bookingId, method);

    switch (result) {
      case ApiSuccess<Payment>(:final data):
        state = AsyncData(data);
        _go(RoutePaths.paymentSuccess.replaceFirst(':paymentId', data.id));
      case ApiError<Payment>(:final message, :final code):
        if (_isUnauthorized(code)) {
          await _redirectToLogin();
        }
        state = AsyncError(message, StackTrace.current);
    }

    return result;
  }

  bool _isUnauthorized(String? code) => code == 'SESSION_EXPIRED' || code == '401';

  bool _isNotFound(String? code, String message) {
    return code == '404' || code == 'NOT_FOUND' || message.toLowerCase().contains('not found');
  }

  Future<void> _redirectToLogin() async {
    await ref.read(appStorageProvider).clearTokens();
    _go(RoutePaths.login);
  }

  void _go(String location) {
    final context = appRouterKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go(location);
    }
  }
}

final paymentControllerProvider = AsyncNotifierProvider<PaymentController, Payment?>(
  PaymentController.new,
);

final bookingDetailsProvider = FutureProvider.family<Booking, String>((ref, bookingId) async {
  final result = await ref.read(bookingRepositoryProvider).getBookingById(bookingId);

  switch (result) {
    case ApiSuccess<Booking>(:final data):
      return data;
    case ApiError<Booking>(:final message, :final code):
      if (code == 'SESSION_EXPIRED' || code == '401') {
        await ref.read(appStorageProvider).clearTokens();
        final context = appRouterKey.currentContext;
        if (context != null) {
          GoRouter.of(context).go(RoutePaths.login);
        }
      }
      throw Exception(message);
  }
});

final reviewFormProvider = StateProvider<ReviewFormState>((ref) {
  return const ReviewFormState();
});

extension ReviewFormControllerX on StateController<ReviewFormState> {
  void setRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void toggleTag(String tag) {
    final tags = [...state.selectedTags];
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    state = state.copyWith(selectedTags: tags);
  }

  void addPhoto(String url) {
    state = state.copyWith(photoUrls: [...state.photoUrls, url]);
  }

  void removePhoto(String url) {
    state = state.copyWith(
      photoUrls: state.photoUrls.where((photo) => photo != url).toList(growable: false),
    );
  }
}

final reviewSubmittingProvider = StateProvider<bool>((ref) => false);
final reviewPhotoUploadingProvider = StateProvider<bool>((ref) => false);
