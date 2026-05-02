import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/credit_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch credit summary on dashboard load
    Future.microtask(() => ref.read(creditProvider.notifier).fetchSummary());
  }

  String _formatCurrency(double value) {
    return NumberFormat('#,##0.00', 'en_US').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final credit = ref.watch(creditProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Loading State ──
          if (credit.isLoading) ...[
            const SizedBox(height: 100),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 100),
          ] else if (credit.error != null) ...[
            // ── Error State ──
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.healthHigh.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Text(credit.error!, style: AppTheme.bodySm.copyWith(color: AppTheme.healthHigh)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.read(creditProvider.notifier).fetchSummary(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ── Total Credit Limit ──
            Text('TOTAL CREDIT LIMIT', style: AppTheme.labelUppercase),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '\$${_formatCurrency(credit.totalCreditLimit).split('.')[0]}',
                    style: AppTheme.headlineXl.copyWith(fontSize: 42),
                  ),
                  TextSpan(
                    text: '.${_formatCurrency(credit.totalCreditLimit).split('.')[1]}',
                    style: AppTheme.headlineXl.copyWith(
                      fontSize: 24,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Used / Available Card ──
            _buildCreditUsageCard(credit),
            const SizedBox(height: 16),

            // ── Utilization Health ──
            _buildUtilizationCard(credit),
            const SizedBox(height: 16),
          ],

          // ── Stellar Points (static for MVP) ──
          _buildStellarPointsCard(),
          const SizedBox(height: 16),

          // ── FD Deposits (static for MVP) ──
          _buildFdDepositsCard(),
          const SizedBox(height: 16),

          // ── Scan to Pay ──
          _buildScanToPayCard(),
          const SizedBox(height: 24),

          // ── Recent Activity ──
          _buildRecentActivity(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCreditUsageCard(CreditState credit) {
    final utilization = credit.totalCreditLimit > 0
        ? credit.usedBalance / credit.totalCreditLimit
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$${_formatCurrency(credit.usedBalance)}',
                      style: AppTheme.titleMd
                          .copyWith(color: AppTheme.primaryBlue)),
                  Text('USED BALANCE', style: AppTheme.labelUppercase),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${_formatCurrency(credit.available)}',
                      style: AppTheme.titleMd),
                  Text('AVAILABLE', style: AppTheme.labelUppercase),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: utilization.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppTheme.dividerColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilizationCard(CreditState credit) {
    final pct = credit.utilizationPercent;
    final health = credit.utilizationHealth;
    final healthColor = pct <= 30
        ? AppTheme.healthGood
        : pct <= 50
            ? AppTheme.healthCaution
            : AppTheme.healthHigh;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              color: AppTheme.textTertiary, size: 18),
          const SizedBox(width: 8),
          Text('UTILIZATION HEALTH', style: AppTheme.labelUppercase),
          const Spacer(),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: healthColor, width: 3),
            ),
            child: Center(
              child: Text(health.substring(0, 1),
                  style: AppTheme.caption.copyWith(
                      color: healthColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${pct.toStringAsFixed(0)}% Utilized',
                  style: AppTheme.titleSm),
              Text(
                  pct <= 30
                      ? 'Excellent standing'
                      : 'Keep under 30% for Excellent',
                  style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStellarPointsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text('STELLAR POINTS', style: AppTheme.labelUppercase),
              const Spacer(),
              Icon(Icons.chevron_right, color: AppTheme.primaryBlue, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: '0 ', style: AppTheme.headlineMd),
              TextSpan(
                  text: 'XLM',
                  style: AppTheme.bodySm.copyWith(fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('REFERRAL MILESTONE',
                  style: AppTheme.labelUppercase.copyWith(fontSize: 10)),
              const Spacer(),
              Text('0/5 Friends',
                  style: AppTheme.caption
                      .copyWith(color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 4,
              backgroundColor: AppTheme.dividerColor,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFdDepositsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.account_balance,
                  color: AppTheme.textTertiary, size: 18),
              const SizedBox(width: 8),
              Text('FD DEPOSITS', style: AppTheme.labelUppercase),
              const Spacer(),
              Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text('\$0.00', style: AppTheme.headlineMd),
          const SizedBox(height: 4),
          Text('No active deposits yet', style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _buildScanToPayCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.scanCardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(Icons.qr_code_2,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                Text('Scan to Pay',
                    style: AppTheme.headlineSm.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('Instant merchant settlement',
                    style: AppTheme.bodySm.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward,
              color: AppTheme.primaryBlue, size: 24),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppTheme.headlineSm),
            Text('View Ledger  >',
                style: AppTheme.bodySm.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Icon(Icons.receipt_long,
                  color: AppTheme.textTertiary, size: 32),
              const SizedBox(height: 8),
              Text('No transactions yet', style: AppTheme.bodySm),
              Text('Make your first payment to see activity here.',
                  style: AppTheme.caption),
            ],
          ),
        ),
      ],
    );
  }
}
