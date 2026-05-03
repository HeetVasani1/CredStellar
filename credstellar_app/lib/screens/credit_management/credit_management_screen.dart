import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/credit_provider.dart';
import '../../providers/fd_provider.dart';
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
    Future.microtask(() {
      ref.read(creditProvider.notifier).fetchSummary();
      ref.read(fdListProvider.notifier).fetchFds();
    });
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

          // ── Active Fixed Deposits ──
          Text('ACTIVE DEPOSITS', style: AppTheme.labelUppercase),
          const SizedBox(height: 12),
          _buildFdList(),
          const SizedBox(height: 24),

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

  void _showFdDetails(Map<String, dynamic> fd) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final principal = (fd['principal_amount'] as num).toDouble();
        final interest = (fd['estimated_interest'] as num).toDouble();
        
        final startDate = DateTime.parse(fd['created_at'].toString());
        final maturityDate = DateTime.parse(fd['maturity_date'].toString());
        final now = DateTime.now();
        final totalDays = maturityDate.difference(startDate).inDays;
        final elapsedDays = now.difference(startDate).inDays;
        final progress = totalDays > 0 ? (elapsedDays / totalDays).clamp(0.0, 1.0) : 0.0;
        final earnedInterest = interest * progress;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(fd['name'] ?? 'Fixed Deposit', style: AppTheme.headlineSm),
                const SizedBox(height: 8),
                Text('Account ending in ${fd['account_number'] ?? '****'}', style: AppTheme.caption),
                const SizedBox(height: 24),
                _detailRow('Principal Amount', '\$${_fmt(principal)}'),
                _detailRow('APY Rate', '${fd['apy_rate']}%'),
                _detailRow('Tenor', '${fd['tenor_months']} Months'),
                _detailRow('Maturity Date', DateFormat('MMM dd, yyyy').format(maturityDate)),
                const Divider(height: 32),
                _detailRow('Total Estimated Interest', '+\$${_fmt(interest)}', isPositive: true),
                _detailRow('Interest Earned So Far', '+\$${_fmt(earnedInterest)}', isPositive: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isPositive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySm),
          Text(
            value,
            style: AppTheme.titleSm.copyWith(
              color: isPositive ? AppTheme.healthGood : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFdList() {
    final fdListState = ref.watch(fdListProvider);
    if (fdListState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (fdListState.fds.isEmpty) {
      return Text('No active deposits.', style: AppTheme.caption);
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fdListState.fds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fd = fdListState.fds[index];
        final principal = (fd['principal_amount'] as num).toDouble();
        final apy = (fd['apy_rate'] as num).toDouble();
        return GestureDetector(
          onTap: () => _showFdDetails(fd),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fd['name'] ?? 'Fixed Deposit', style: AppTheme.titleSm),
                    const SizedBox(height: 4),
                    Text('${fd['tenor_months']} Months @ $apy%', style: AppTheme.caption),
                  ],
                ),
                Text('\$${_fmt(principal)}', style: AppTheme.titleSm.copyWith(color: AppTheme.primaryBlue)),
              ],
            ),
          ),
        );
      },
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
              ref.read(fdListProvider.notifier).fetchFds();
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
