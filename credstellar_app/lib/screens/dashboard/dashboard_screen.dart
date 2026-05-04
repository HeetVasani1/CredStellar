import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/credit_provider.dart';
import '../../providers/fd_provider.dart';
import '../add_fixed_deposit/add_fixed_deposit_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(creditProvider.notifier).fetchSummary();
      ref.read(fdListProvider.notifier).fetchFds();
    });
  }

  String _formatCurrency(double value) {
    return NumberFormat('#,##0.00', 'en_US').format(value);
  }

  String _formatPct(double pct) {
    if (pct > 0 && pct < 1) return '<1';
    return pct.toStringAsFixed(0);
  }

  void _showFdDetails(Map<String, dynamic> fd) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final principal = (fd['principal_amount'] as num).toDouble();
        final interest = (fd['estimated_interest'] as num).toDouble();
        
        // Simulating earned interest based on start date (for MVP, showing proportion of estimated)
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
                _detailRow('Principal Amount', '\$${_formatCurrency(principal)}'),
                _detailRow('APY Rate', '${fd['apy_rate']}%'),
                _detailRow('Tenor', '${fd['tenor_months']} Months'),
                _detailRow('Maturity Date', DateFormat('MMM dd, yyyy').format(maturityDate)),
                const Divider(height: 32),
                _detailRow('Total Estimated Interest', '+\$${_formatCurrency(interest)}', isPositive: true),
                _detailRow('Interest Earned So Far', '+\$${_formatCurrency(earnedInterest)}', isPositive: true),
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

  @override
  Widget build(BuildContext context) {
    final credit = ref.watch(creditProvider);
    final fdListState = ref.watch(fdListProvider);

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
                    onPressed: () {
                      ref.read(creditProvider.notifier).fetchSummary();
                      ref.read(fdListProvider.notifier).fetchFds();
                    },
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

          // ── FD Deposits ──
          _buildFdDepositsCard(fdListState),
          const SizedBox(height: 16),

          // ── Scan to Pay ──
          GestureDetector(
            onTap: () {
              widget.onSwitchTab?.call(2);
            },
            child: _buildScanToPayCard(),
          ),
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

  void _showUtilizationDetails(CreditState credit) {
    final pct = credit.utilizationPercent;
    final healthColor = pct <= 30
        ? AppTheme.healthGood
        : pct <= 50
            ? AppTheme.healthCaution
            : AppTheme.healthHigh;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                Text('Credit Utilization Health', style: AppTheme.headlineSm),
                const SizedBox(height: 20),

                // Gauge
                Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: (pct / 100).clamp(0.0, 1.0),
                            strokeWidth: 10,
                            backgroundColor: AppTheme.dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${_formatPct(pct)}%',
                                style: AppTheme.headlineMd.copyWith(color: healthColor)),
                            Text(credit.utilizationHealth,
                                style: AppTheme.caption.copyWith(color: healthColor, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Breakdown
                _detailRow('Total Credit Limit', '\$${_formatCurrency(credit.totalCreditLimit)}'),
                _detailRow('Used Balance', '\$${_formatCurrency(credit.usedBalance)}'),
                _detailRow('Available Credit', '\$${_formatCurrency(credit.available)}', isPositive: true),
                const Divider(height: 24),

                // Tips
                Text('CREDIT HEALTH TIPS', style: AppTheme.labelUppercase),
                const SizedBox(height: 12),
                _tipRow(Icons.check_circle, 'Keep utilization under 30% for Excellent rating',
                    pct <= 30 ? AppTheme.healthGood : AppTheme.textTertiary),
                _tipRow(Icons.trending_up, 'Add more FDs to increase your credit limit',
                    AppTheme.primaryBlue),
                _tipRow(Icons.payments_outlined, 'Pay off balances quickly to lower utilization',
                    pct > 50 ? AppTheme.healthHigh : AppTheme.textTertiary),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tipRow(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTheme.bodySm)),
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

    return GestureDetector(
      onTap: () => _showUtilizationDetails(credit),
      child: Container(
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
                Text('${_formatPct(pct)}% Utilized',
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

  Widget _buildFdDepositsCard(FdListState fdListState) {
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
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddFixedDepositScreen()),
                  );
                  ref.read(creditProvider.notifier).fetchSummary();
                  ref.read(fdListProvider.notifier).fetchFds();
                },
                child: Icon(Icons.add_circle, color: AppTheme.primaryBlue, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (fdListState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (fdListState.error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fdListState.error!, style: AppTheme.caption.copyWith(color: AppTheme.healthHigh)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => ref.read(fdListProvider.notifier).fetchFds(),
                  child: Text('Tap to retry', style: AppTheme.bodySm.copyWith(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                ),
              ],
            )
          else if (fdListState.fds.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\$0.00', style: AppTheme.headlineMd),
                const SizedBox(height: 4),
                Text('No active deposits yet', style: AppTheme.caption),
              ],
            )
          else
            ListView.separated(
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fd['name'] ?? 'Fixed Deposit', style: AppTheme.titleSm),
                            Text('${fd['tenor_months']} Months @ $apy%', style: AppTheme.caption),
                          ],
                        ),
                        Text('\$${_formatCurrency(principal)}', style: AppTheme.titleSm),
                      ],
                    ),
                  ),
                );
              },
            ),
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
            GestureDetector(
              onTap: () {
                widget.onSwitchTab?.call(3);
              },
              child: Text('View Ledger  >',
                  style: AppTheme.bodySm.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600)),
            ),
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
              Text('See ledger for all activity', style: AppTheme.bodySm),
            ],
          ),
        ),
      ],
    );
  }
}

