import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';
import 'credit_provider.dart';

/// Payment preview data from API
class PaymentPreviewData {
  final String merchantName;
  final double amountLocal;
  final String localCurrency;
  final double amountUsd;
  final double amountXlm;
  final double fxRate;
  final double xlmRate;
  final double stellarFeeXlm;
  final double availableCredit;
  final bool canPay;

  const PaymentPreviewData({
    required this.merchantName,
    required this.amountLocal,
    required this.localCurrency,
    required this.amountUsd,
    required this.amountXlm,
    required this.fxRate,
    required this.xlmRate,
    required this.stellarFeeXlm,
    required this.availableCredit,
    required this.canPay,
  });

  factory PaymentPreviewData.fromJson(Map<String, dynamic> json) {
    final credit = json['credit'] as Map<String, dynamic>? ?? {};
    return PaymentPreviewData(
      merchantName: json['merchant_name']?.toString() ?? 'Unknown',
      amountLocal: (json['amount_local'] as num?)?.toDouble() ?? 0,
      localCurrency: json['local_currency']?.toString() ?? 'INR',
      amountUsd: (json['amount_usd'] as num?)?.toDouble() ?? 0,
      amountXlm: (json['amount_xlm'] as num?)?.toDouble() ?? 0,
      fxRate: (json['fx_rate'] as num?)?.toDouble() ?? 0,
      xlmRate: (json['xlm_rate'] as num?)?.toDouble() ?? 0,
      stellarFeeXlm: (json['stellar_fee_xlm'] as num?)?.toDouble() ?? 0,
      availableCredit: (credit['available'] as num?)?.toDouble() ?? 0,
      canPay: json['can_pay'] == true,
    );
  }
}

/// Payment state
class PaymentState {
  final bool isPreviewLoading;
  final bool isExecuteLoading;
  final bool isSuccess;
  final PaymentPreviewData? preview;
  final Map<String, dynamic>? executeResult;
  final String? error;

  const PaymentState({
    this.isPreviewLoading = false,
    this.isExecuteLoading = false,
    this.isSuccess = false,
    this.preview,
    this.executeResult,
    this.error,
  });

  PaymentState copyWith({
    bool? isPreviewLoading,
    bool? isExecuteLoading,
    bool? isSuccess,
    PaymentPreviewData? preview,
    Map<String, dynamic>? executeResult,
    String? error,
  }) {
    return PaymentState(
      isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
      isExecuteLoading: isExecuteLoading ?? this.isExecuteLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      preview: preview ?? this.preview,
      executeResult: executeResult ?? this.executeResult,
      error: error,
    );
  }
}

/// Payment notifier — preview + execute with credit refresh.
class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _paymentService;
  final CreditNotifier _creditNotifier;

  PaymentNotifier(this._paymentService, this._creditNotifier)
      : super(const PaymentState());

  /// Fetch payment preview for a given amount + merchant
  Future<void> fetchPreview({
    required double amountLocal,
    required String merchantName,
  }) async {
    state = state.copyWith(isPreviewLoading: true, error: null);
    try {
      final data = await _paymentService.preview(
        amountLocal: amountLocal,
        merchantName: merchantName,
      );
      final previewData = PaymentPreviewData.fromJson(data);
      state = PaymentState(preview: previewData);
    } catch (e) {
      state = state.copyWith(
        isPreviewLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Execute payment
  Future<bool> executePayment({
    required double amountLocal,
    required String merchantName,
  }) async {
    state = state.copyWith(isExecuteLoading: true, error: null);
    try {
      final data = await _paymentService.execute(
        amountLocal: amountLocal,
        merchantName: merchantName,
      );
      state = PaymentState(isSuccess: true, executeResult: data);

      // Refresh credit so dashboard shows updated balance
      await _creditNotifier.fetchSummary();
      return true;
    } catch (e) {
      state = state.copyWith(
        isExecuteLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset state (when entering the flow again)
  void reset() {
    state = const PaymentState();
  }
}

// ── Providers ──

final paymentServiceProvider =
    Provider<PaymentService>((ref) => PaymentService());

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(
    ref.read(paymentServiceProvider),
    ref.read(creditProvider.notifier),
  );
});
