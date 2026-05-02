import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? result;
  final String merchantName;

  const PaymentSuccessScreen({
    super.key,
    this.result,
    required this.merchantName,
  });

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    final tx = result?['transaction'] as Map<String, dynamic>? ?? {};
    final stellar = result?['stellar'] as Map<String, dynamic>? ?? {};
    final credit = result?['credit'] as Map<String, dynamic>? ?? {};

    final amountUsd = (tx['amount_usd'] as num?)?.toDouble() ?? 0;
    final amountLocal = (tx['amount_local'] as num?)?.toDouble() ?? 0;
    final amountXlm = (tx['amount_xlm'] as num?)?.toDouble() ?? 0;
    final txHash = stellar['tx_hash']?.toString() ?? '';
    final available = (credit['available'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ── Success icon ──
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.healthGood,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.healthGood.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              Text('Payment Successful', style: AppTheme.headlineMd),
              const SizedBox(height: 8),
              Text(merchantName, style: AppTheme.bodySm),
              const SizedBox(height: 24),

              // ── Amount ──
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
                    Text('AMOUNT PAID', style: AppTheme.labelUppercase),
                    const SizedBox(height: 8),
                    Text('₹${_fmt(amountLocal)}',
                        style: AppTheme.headlineXl.copyWith(fontSize: 42)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                          '≈ \$${_fmt(amountUsd)} • ${amountXlm.toStringAsFixed(4)} XLM',
                          style: AppTheme.titleSm
                              .copyWith(color: AppTheme.primaryBlue)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Details ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    _detailRow('Status', 'Cleared', isGreen: true),
                    const SizedBox(height: 12),
                    _detailRow('Remaining Credit', '\$${_fmt(available)}'),
                    if (txHash.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _detailRow('Tx Hash',
                          '${txHash.substring(0, 8)}...${txHash.substring(txHash.length - 6)}'),
                    ],
                    const SizedBox(height: 12),
                    _detailRow('Network', stellar['network']?.toString() ?? 'Stellar Testnet'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Done Button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.ctaGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXl)),
                    ),
                    child: Text('Done',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodySm),
        if (isGreen)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.healthGood.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(value,
                style: AppTheme.caption.copyWith(
                    color: AppTheme.healthGood,
                    fontWeight: FontWeight.w600)),
          )
        else
          Flexible(
            child: Text(value,
                style: AppTheme.titleSm, textAlign: TextAlign.right),
          ),
      ],
    );
  }
}
