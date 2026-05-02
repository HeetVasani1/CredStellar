import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/credit_service.dart';

/// Credit state — holds credit summary data, loading, and error.
class CreditState {
  final bool isLoading;
  final double totalCreditLimit;
  final double usedBalance;
  final double available;
  final String? error;

  const CreditState({
    this.isLoading = false,
    this.totalCreditLimit = 0,
    this.usedBalance = 0,
    this.available = 0,
    this.error,
  });

  double get utilizationPercent =>
      totalCreditLimit > 0 ? (usedBalance / totalCreditLimit) * 100 : 0;

  String get utilizationHealth {
    final pct = utilizationPercent;
    if (pct <= 30) return 'Excellent';
    if (pct <= 50) return 'Good';
    return 'High';
  }

  CreditState copyWith({
    bool? isLoading,
    double? totalCreditLimit,
    double? usedBalance,
    double? available,
    String? error,
  }) {
    return CreditState(
      isLoading: isLoading ?? this.isLoading,
      totalCreditLimit: totalCreditLimit ?? this.totalCreditLimit,
      usedBalance: usedBalance ?? this.usedBalance,
      available: available ?? this.available,
      error: error,
    );
  }
}

/// Credit notifier — fetches and holds credit summary.
class CreditNotifier extends StateNotifier<CreditState> {
  final CreditService _creditService;

  CreditNotifier(this._creditService) : super(const CreditState());

  Future<void> fetchSummary() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _creditService.getSummary();
      state = CreditState(
        totalCreditLimit: (data['total_credit_limit'] as num).toDouble(),
        usedBalance: (data['used_balance'] as num).toDouble(),
        available: (data['available'] as num).toDouble(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

// ── Providers ──

final creditServiceProvider =
    Provider<CreditService>((ref) => CreditService());

final creditProvider =
    StateNotifierProvider<CreditNotifier, CreditState>((ref) {
  return CreditNotifier(ref.read(creditServiceProvider));
});
