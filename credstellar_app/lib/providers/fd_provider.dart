import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fd_service.dart';
import 'credit_provider.dart';

/// APY rates matching backend (per tenor)
const Map<int, double> apyRates = {
  3: 4.15,
  6: 4.50,
  12: 5.25,
};

/// FD creation state
class FdCreateState {
  final bool isLoading;
  final bool isSuccess;
  final Map<String, dynamic>? result;
  final String? error;

  const FdCreateState({
    this.isLoading = false,
    this.isSuccess = false,
    this.result,
    this.error,
  });

  FdCreateState copyWith({
    bool? isLoading,
    bool? isSuccess,
    Map<String, dynamic>? result,
    String? error,
  }) {
    return FdCreateState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      result: result ?? this.result,
      error: error,
    );
  }
}

/// FD notifier — handles FD creation and refreshes credit afterward.
class FdNotifier extends StateNotifier<FdCreateState> {
  final FdService _fdService;
  final CreditNotifier _creditNotifier;

  FdNotifier(this._fdService, this._creditNotifier)
      : super(const FdCreateState());

  /// Create a fixed deposit
  Future<bool> createFd(double amount, int tenorMonths) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final data = await _fdService.createFd(
        amount: amount,
        tenorMonths: tenorMonths,
      );
      state = FdCreateState(isSuccess: true, result: data);

      // Refresh credit summary so dashboard reflects the new limit
      await _creditNotifier.fetchSummary();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset state (for re-entering the screen)
  void reset() {
    state = const FdCreateState();
  }

  /// Calculate estimated interest locally (mirrors backend logic)
  static double estimateInterest(double principal, int tenorMonths) {
    final apy = apyRates[tenorMonths] ?? 0;
    return double.parse(
        (principal * (apy / 100) * (tenorMonths / 12)).toStringAsFixed(2));
  }

  /// Get APY for a tenor
  static double getApy(int tenorMonths) => apyRates[tenorMonths] ?? 0;
}

// ── Providers ──

final fdServiceProvider = Provider<FdService>((ref) => FdService());

final fdProvider =
    StateNotifierProvider<FdNotifier, FdCreateState>((ref) {
  return FdNotifier(
    ref.read(fdServiceProvider),
    ref.read(creditProvider.notifier),
  );
});
