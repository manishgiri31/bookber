import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/providers.dart';

class WalletState {
  final double balance;
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final String? error;

  const WalletState({
    this.balance = 0,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    double? balance,
    List<Map<String, dynamic>>? transactions,
    bool? isLoading,
    String? error,
  }) =>
      WalletState(
        balance: balance ?? this.balance,
        transactions: transactions ?? this.transactions,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    Future.microtask(loadWallet);
    return const WalletState(isLoading: true);
  }

  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final results = await Future.wait<dynamic>([
        client.get<dynamic>(ApiEndpoints.walletBalance),
        client.get<dynamic>(ApiEndpoints.walletTransactions),
      ]);
      final balRes = results[0] is Map<String, dynamic>
          ? results[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final txRes = results[1] is Map<String, dynamic>
          ? results[1] as Map<String, dynamic>
          : <String, dynamic>{};
      final balance = (balRes['balance'] as num?)?.toDouble() ?? 0.0;
      final txList = (txRes['transactions'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList() ?? [];
      state = state.copyWith(
          balance: balance, transactions: txList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);
