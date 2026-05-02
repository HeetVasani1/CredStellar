import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/fd_provider.dart';

class AddFixedDepositScreen extends ConsumerStatefulWidget {
  const AddFixedDepositScreen({super.key});

  @override
  ConsumerState<AddFixedDepositScreen> createState() =>
      _AddFixedDepositScreenState();
}

class _AddFixedDepositScreenState
    extends ConsumerState<AddFixedDepositScreen> {
  int _selectedTenor = 6;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset FD state when entering screen
    Future.microtask(() => ref.read(fdProvider.notifier).reset());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _parsedAmount {
    final text = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(text) ?? 0;
  }

  double get _currentApy => FdNotifier.getApy(_selectedTenor);

  double get _estimatedInterest =>
      FdNotifier.estimateInterest(_parsedAmount, _selectedTenor);

  double get _totalPayout => _parsedAmount + _estimatedInterest;

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

  Future<void> _handleConfirm() async {
    final amount = _parsedAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid deposit amount.')),
      );
      return;
    }

    final success =
        await ref.read(fdProvider.notifier).createFd(amount, _selectedTenor);

    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    final fdState = ref.read(fdProvider);
    final fd = fdState.result?['fixed_deposit'] as Map<String, dynamic>?;
    final credit = fdState.result?['credit'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.healthGood.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.healthGood, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Deposit Created!', style: AppTheme.headlineSm),
            const SizedBox(height: 8),
            if (fd != null) ...[
              Text(fd['name'] ?? '', style: AppTheme.bodySm),
              const SizedBox(height: 4),
              Text('\$${_fmt((fd['principal_amount'] as num).toDouble())}',
                  style: AppTheme.headlineMd
                      .copyWith(color: AppTheme.primaryBlue)),
            ],
            const SizedBox(height: 12),
            if (credit != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Credit Limit', style: AppTheme.caption),
                    Text(
                        '\$${_fmt((credit['total_credit_limit'] as num).toDouble())}',
                        style: AppTheme.titleSm
                            .copyWith(color: AppTheme.healthGood)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              ),
              child: const Text('Done',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fdState = ref.watch(fdProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Fixed Deposit', style: AppTheme.titleMd),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── APY Hero Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppTheme.scanCardGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Column(
                children: [
                  Text('CURRENT APY',
                      style: AppTheme.labelUppercase
                          .copyWith(color: Colors.white54)),
                  const SizedBox(height: 8),
                  Text('${_currentApy.toStringAsFixed(2)}%',
                      style: AppTheme.headlineXl
                          .copyWith(color: Colors.white, fontSize: 48)),
                  const SizedBox(height: 4),
                  Text('Annual Percentage Yield',
                      style: AppTheme.caption.copyWith(color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Amount Input ──
            Text('Deposit Amount', style: AppTheme.titleSm),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Text('\$',
                      style: AppTheme.headlineMd
                          .copyWith(color: AppTheme.textTertiary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      style: AppTheme.headlineMd,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text('USD',
                        style: AppTheme.titleSm
                            .copyWith(color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tenor Selection ──
            Text('Lock-in Period', style: AppTheme.titleSm),
            const SizedBox(height: 12),
            Row(
              children: [
                _tenorChip(3, '4.15%'),
                const SizedBox(width: 10),
                _tenorChip(6, '4.50%'),
                const SizedBox(width: 10),
                _tenorChip(12, '5.25%'),
              ],
            ),
            const SizedBox(height: 24),

            // ── Credit Power Boost ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.healthGood.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up,
                          color: AppTheme.healthGood, size: 18),
                      const SizedBox(width: 8),
                      Text('CREDIT POWER BOOST',
                          style: AppTheme.labelUppercase
                              .copyWith(color: AppTheme.healthGood)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('New Credit Line', style: AppTheme.bodySm),
                      Text(
                          _parsedAmount > 0
                              ? '+\$${_fmt(_parsedAmount)}'
                              : '+\$0.00',
                          style: AppTheme.headlineSm
                              .copyWith(color: AppTheme.healthGood)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Summary ──
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
                  _summaryRow('Principal', '\$${_fmt(_parsedAmount)}'),
                  const SizedBox(height: 12),
                  _summaryRow('APY Rate', '${_currentApy.toStringAsFixed(2)}%'),
                  const SizedBox(height: 12),
                  _summaryRow('Lock-in', '$_selectedTenor Months'),
                  const SizedBox(height: 12),
                  _summaryRow(
                      'Est. Interest', '\$${_fmt(_estimatedInterest)}'),
                  const Divider(height: 24, color: AppTheme.dividerColor),
                  _summaryRow('Total at Maturity', '\$${_fmt(_totalPayout)}',
                      isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Error ──
            if (fdState.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.healthHigh.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Text(fdState.error!,
                    style: AppTheme.bodySm
                        .copyWith(color: AppTheme.healthHigh)),
              ),
              const SizedBox(height: 16),
            ],

            // ── Confirm Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: fdState.isLoading
                      ? const LinearGradient(
                          colors: [Color(0xFF4A4A5E), Color(0xFF4A4A5E)])
                      : AppTheme.ctaGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: ElevatedButton(
                  onPressed: fdState.isLoading ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXl)),
                  ),
                  child: fdState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Confirm Deposit',
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
    );
  }

  Widget _tenorChip(int months, String apy) {
    final isSelected = _selectedTenor == months;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTenor = months),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryDark : AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: isSelected ? [] : AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Text('$months',
                  style: AppTheme.headlineSm.copyWith(
                      color:
                          isSelected ? Colors.white : AppTheme.textPrimary)),
              Text('months',
                  style: AppTheme.caption.copyWith(
                      color: isSelected
                          ? Colors.white54
                          : AppTheme.textTertiary)),
              const SizedBox(height: 6),
              Text(apy,
                  style: AppTheme.caption.copyWith(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.healthGood,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isBold ? AppTheme.titleSm : AppTheme.bodySm),
        Text(value, style: isBold ? AppTheme.titleMd : AppTheme.titleSm),
      ],
    );
  }
}
