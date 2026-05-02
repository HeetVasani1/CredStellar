import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transaction_service.dart';

/// Transaction list state
class TransactionListState {
  final bool isLoading;
  final List<Map<String, dynamic>> transactions;
  final String? error;

  const TransactionListState({
    this.isLoading = false,
    this.transactions = const [],
    this.error,
  });

  TransactionListState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? transactions,
    String? error,
  }) {
    return TransactionListState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      error: error,
    );
  }
}

/// Transaction detail state
class TransactionDetailState {
  final bool isLoading;
  final Map<String, dynamic>? transaction;
  final String? error;

  const TransactionDetailState({
    this.isLoading = false,
    this.transaction,
    this.error,
  });

  TransactionDetailState copyWith({
    bool? isLoading,
    Map<String, dynamic>? transaction,
    String? error,
  }) {
    return TransactionDetailState(
      isLoading: isLoading ?? this.isLoading,
      transaction: transaction ?? this.transaction,
      error: error,
    );
  }
}

/// Transaction list notifier
class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final TransactionService _service;

  TransactionListNotifier(this._service)
      : super(const TransactionListState());

  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getAll();
      state = TransactionListState(transactions: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

/// Transaction detail notifier
class TransactionDetailNotifier extends StateNotifier<TransactionDetailState> {
  final TransactionService _service;

  TransactionDetailNotifier(this._service)
      : super(const TransactionDetailState());

  Future<void> fetchById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getById(id);
      state = TransactionDetailState(transaction: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const TransactionDetailState();
  }
}

// ── Providers ──

final transactionServiceProvider =
    Provider<TransactionService>((ref) => TransactionService());

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  return TransactionListNotifier(ref.read(transactionServiceProvider));
});

final transactionDetailProvider = StateNotifierProvider<
    TransactionDetailNotifier, TransactionDetailState>((ref) {
  return TransactionDetailNotifier(ref.read(transactionServiceProvider));
});
