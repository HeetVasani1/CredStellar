import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/credit_provider.dart';
import '../add_fixed_deposit/add_fixed_deposit_screen.dart';

class CreditManagementScreen extends ConsumerStatefulWidget {
  const CreditManagementScreen({super.key});

  @override
  ConsumerState<CreditManagementScreen> createState() =>
      _CreditManagementScreenState();
}

class _CreditManagementScreenState
    extends ConsumerState<CreditManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(creditProvider.notifier).fetchSummary());
  }

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    final credit = ref.watch(creditProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Manage\nCredit Power', style: AppTheme.headlineXl),
          const SizedBox(height: 8),
          Text('Your credit line is backed by your Stellar assets.',
              style: AppTheme.bodySm),
          const SizedBox(height: 24),

          // ── Loading ──
          if (credit.isLoading) ...[
            const SizedBox(height: 60),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 60),
          ] else if (credit.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.healthHigh.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Text(credit.error!,
                      style: AppTheme.bodySm
                          .copyWith(color: AppTheme.healthHigh)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.read(creditProvider.notifier).fetchSummary(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ── Available Credit Card ──
            _buildCreditCard(credit),
            const SizedBox(height: 16),

            // ── USD / XLM Split ──
            _buildCurrencySplit(credit),
          ],

          const SizedBox(height: 32),

          // ── Add New FD Button ──
          _buildAddFdButton(context),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Adding a new Fixed Deposit instantly increases\nyour available credit line.',
              textAlign: TextAlign.center,
              style: AppTheme.caption,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCreditCard(CreditState credit) {
    final utilization = credit.utilizationPercent;
    final utilizationFraction = credit.totalCreditLimit > 0
        ? credit.usedBalance / credit.totalCreditLimit
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Credit', style: AppTheme.bodySm),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${_fmt(credit.available)}',
                  style: AppTheme.headlineXl.copyWith(fontSize: 34)),
              Text('${utilization.toStringAsFixed(0)}% Utilized',
                  style: AppTheme.bodySm.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: utilizationFraction.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppTheme.dividerColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Used: \$${_fmt(credit.usedBalance)}',
                  style: AppTheme.caption),
              Text('Limit: \$${_fmt(credit.totalCreditLimit)}',
                  style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySplit(CreditState credit) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('USD CREDIT', style: AppTheme.labelUppercase),
                const SizedBox(height: 8),
                Text('\$${_fmt(credit.available)}',
                    style: AppTheme.headlineSm),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL LIMIT',
                    style: AppTheme.labelUppercase
                        .copyWith(color: AppTheme.primaryBlue)),
                const SizedBox(height: 8),
                Text('\$${_fmt(credit.totalCreditLimit)}',
                    style: AppTheme.headlineSm),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddFdButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.ctaGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const AddFixedDepositScreen()),
            );
            // Refresh credit after returning from FD screen
            if (mounted) {
              ref.read(creditProvider.notifier).fetchSummary();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Add New FD',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
