import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/providers.dart';

// ─── Payment models ───────────────────────────────────────────────────────────

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final double amount;
  final String method;
  final String status;
  final String? transactionId;
  final DateTime createdAt;

  bool get isPaid => status == 'PAID';
  bool get isRefunded => status == 'REFUNDED' || status == 'PARTIALLY_REFUNDED';

  factory PaymentRecord.fromJson(Map<String, dynamic> j) => PaymentRecord(
        id: j['id']?.toString() ?? '',
        bookingId: j['bookingId']?.toString() ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        method: j['method']?.toString() ?? 'CASH',
        status: j['status']?.toString() ?? 'PENDING',
        transactionId: j['transactionId']?.toString(),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class RazorpayOrderResult {
  const RazorpayOrderResult({
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.keyId,
    required this.isStub,
  });

  final String razorpayOrderId;
  final double amount;
  final String currency;
  final String keyId;
  final bool isStub;

  factory RazorpayOrderResult.fromJson(Map<String, dynamic> j) =>
      RazorpayOrderResult(
        razorpayOrderId: j['razorpayOrderId']?.toString() ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        currency: j['currency']?.toString() ?? 'INR',
        keyId: j['keyId']?.toString() ?? '',
        isStub: (j['isStub'] as bool?) ?? false,
      );
}

// ─── Payment history provider ─────────────────────────────────────────────────

final paymentHistoryProvider =
    FutureProvider.autoDispose<List<PaymentRecord>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final data =
        await api.get<Map<String, dynamic>>(ApiEndpoints.paymentHistory);
    final list = data['data'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(PaymentRecord.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
});

// ─── Checkout state ───────────────────────────────────────────────────────────

sealed class CheckoutState {
  const CheckoutState();
}

final class CheckoutIdle extends CheckoutState {
  const CheckoutIdle();
}

final class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

final class CheckoutOrderReady extends CheckoutState {
  const CheckoutOrderReady(this.order);
  final RazorpayOrderResult order;
}

final class CheckoutSuccess extends CheckoutState {
  const CheckoutSuccess(this.payment);
  final PaymentRecord payment;
}

final class CheckoutError extends CheckoutState {
  const CheckoutError(this.message);
  final String message;
}

class CheckoutNotifier extends AutoDisposeNotifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutIdle();

  Future<RazorpayOrderResult?> createOrder(
      String bookingId, double amount) async {
    state = const CheckoutLoading();
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.post<Map<String, dynamic>>(
        ApiEndpoints.razorpayOrder,
        body: {'bookingId': bookingId, 'amount': amount},
      );
      final order = RazorpayOrderResult.fromJson(data);
      state = CheckoutOrderReady(order);
      return order;
    } catch (e) {
      state = CheckoutError(e.toString());
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    state = const CheckoutLoading();
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.post<Map<String, dynamic>>(
        ApiEndpoints.razorpayVerify,
        body: {
          'bookingId': bookingId,
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      final payment = PaymentRecord.fromJson(
          data['payment'] as Map<String, dynamic>? ?? data);
      state = CheckoutSuccess(payment);
      return true;
    } catch (e) {
      state = CheckoutError(e.toString());
      return false;
    }
  }

  Future<bool> payAtShop(String bookingId, double amount) async {
    state = const CheckoutLoading();
    try {
      final api = ref.read(apiClientProvider);
      final payment = await api.post<Map<String, dynamic>>(
        ApiEndpoints.payments,
        body: {
          'bookingId': bookingId,
          'amount': amount,
          'method': 'CASH',
          'idempotencyKey': 'cash_${bookingId}_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
      await api.post<void>(
        ApiEndpoints.processPayment,
        body: {
          'paymentId': payment['id']?.toString() ?? payment['payment']?['id']?.toString() ?? '',
          'transactionId': 'cash_${DateTime.now().millisecondsSinceEpoch}',
          'gatewayResponse': {'method': 'CASH'},
        },
      );
      state = CheckoutSuccess(PaymentRecord.fromJson(
          payment['payment'] as Map<String, dynamic>? ?? payment));
      return true;
    } catch (e) {
      state = CheckoutError(e.toString());
      return false;
    }
  }

  void reset() => state = const CheckoutIdle();
}

final checkoutProvider =
    AutoDisposeNotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
);
