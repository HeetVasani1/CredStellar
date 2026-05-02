import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/payment_provider.dart';
import '../payment_success/payment_success_screen.dart';

class PaymentPreviewScreen extends ConsumerStatefulWidget {
  final String merchantName;
  final String merchantId;

  const PaymentPreviewScreen({
    super.key,
    required this.merchantName,
    this.merchantId = '',
  });

  @override
  ConsumerState<PaymentPreviewScreen> createState() =>
      _PaymentPreviewScreenState();
}

class _PaymentPreviewScreenState extends ConsumerState<PaymentPreviewScreen> {
  final TextEditingController _amountController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(paymentProvider.notifier).reset());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  double get _parsedAmount {
    final text = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(text) ?? 0;
  }

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

  /// Debounced preview fetch — waits 600ms after user stops typing
  void _onAmountChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final amount = _parsedAmount;
      if (amount > 0) {
        ref.read(paymentProvider.notifier).fetchPreview(
              amountLocal: amount,
              merchantName: widget.merchantName,
            );
      }
    });
    setState(() {}); // Rebuild to update button state
  }

  /// Pick a quick amount chip
  void _selectQuickAmount(int amount) {
    _amountController.text = amount.toString();
    _onAmountChanged('');
  }

  /// Execute payment
  Future<void> _handlePay() async {
    final amount = _parsedAmount;
    if (amount <= 0) return;

    final success = await ref.read(paymentProvider.notifier).executePayment(
          amountLocal: amount,
          merchantName: widget.merchantName,
        );

    if (success && mounted) {
      final result = ref.read(paymentProvider).executeResult;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            result: result,
            merchantName: widget.merchantName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = ref.watch(paymentProvider);
    final preview = payment.preview;
    final hasValidAmount = _parsedAmount > 0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Payment', style: AppTheme.titleMd),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ── Secure Badge ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('SECURE PAYMENT', style: AppTheme.labelUppercase),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Merchant Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  // Merchant icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: const Icon(Icons.store,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.merchantName, style: AppTheme.headlineMd),
                  if (widget.merchantId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(widget.merchantId, style: AppTheme.caption),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Amount Input ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ENTER AMOUNT', style: AppTheme.labelUppercase),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('₹',
                          style: AppTheme.headlineLg
                              .copyWith(color: AppTheme.textTertiary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          onChanged: _onAmountChanged,
                          style: AppTheme.headlineXl.copyWith(fontSize: 36),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: AppTheme.headlineXl.copyWith(
                                fontSize: 36,
                                color: AppTheme.textTertiary),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text('INR',
                            style: AppTheme.titleSm
                                .copyWith(color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick amount chips
                  Row(
                    children: [
                      _quickChip(100),
                      const SizedBox(width: 8),
                      _quickChip(500),
                      const SizedBox(width: 8),
                      _quickChip(1000),
                      const SizedBox(width: 8),
                      _quickChip(2000),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Preview Loading ──
            if (payment.isPreviewLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),

            // ── Preview Error ──
            if (payment.error != null && !payment.isExecuteLoading) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.healthHigh.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Text(payment.error!,
                    style: AppTheme.bodySm
                        .copyWith(color: AppTheme.healthHigh)),
              ),
              const SizedBox(height: 16),
            ],

            // ── Conversion Details (only when preview loaded) ──
            if (preview != null && !payment.isPreviewLoading) ...[
              // USD / XLM pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_money,
                        size: 16, color: AppTheme.primaryBlue),
                    Text('≈ \$${_fmt(preview.amountUsd)} USD',
                        style: AppTheme.titleSm
                            .copyWith(color: AppTheme.primaryBlue)),
                    Container(
                      width: 1,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: AppTheme.dividerColor,
                    ),
                    Text('${preview.amountXlm.toStringAsFixed(4)} XLM',
                        style: AppTheme.titleSm),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // FX + Stellar fee row
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.trending_up,
                      label: 'APPLIED FX',
                      value: '1 USD = ₹${_fmt(preview.fxRate)}',
                      badge: 'Market Rate',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      icon: Icons.bolt,
                      label: 'STELLAR FEE',
                      value: '${preview.stellarFeeXlm} XLM',
                      subtitle: 'Minimal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Credit source
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(Icons.credit_card,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stellar Credit Line',
                              style: AppTheme.titleSm),
                          Text(
                              'Available: \$${_fmt(preview.availableCredit)}',
                              style: AppTheme.caption),
                        ],
                      ),
                    ),
                    if (!preview.canPay)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.healthHigh.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text('Insufficient',
                            style: AppTheme.caption.copyWith(
                                color: AppTheme.healthHigh,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Pay Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: (hasValidAmount &&
                          preview != null &&
                          preview.canPay &&
                          !payment.isExecuteLoading)
                      ? AppTheme.ctaGradient
                      : const LinearGradient(
                          colors: [Color(0xFF4A4A5E), Color(0xFF4A4A5E)]),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: ElevatedButton(
                  onPressed: (hasValidAmount &&
                          preview != null &&
                          preview.canPay &&
                          !payment.isExecuteLoading &&
                          !payment.isPreviewLoading)
                      ? _handlePay
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXl)),
                  ),
                  child: payment.isExecuteLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Pay with Credit',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            const Icon(Icons.fingerprint,
                                color: Colors.white, size: 22),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_outlined,
                    size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 6),
                Text('Secured by Sovereign Ledger Technology',
                    style: AppTheme.caption),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(int amount) {
    final isSelected = _parsedAmount == amount.toDouble();
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectQuickAmount(amount),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryDark : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Center(
            child: Text('₹$amount',
                style: AppTheme.caption.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: AppTheme.labelUppercase)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.titleSm),
          const SizedBox(height: 4),
          if (badge != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.healthGood.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(badge,
                  style: AppTheme.caption.copyWith(
                      color: AppTheme.healthGood,
                      fontWeight: FontWeight.w600,
                      fontSize: 11)),
            ),
          if (subtitle != null) Text(subtitle, style: AppTheme.caption),
        ],
      ),
    );
  }
}
