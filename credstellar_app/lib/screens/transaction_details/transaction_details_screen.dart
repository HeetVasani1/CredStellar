import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/transaction_provider.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  final String txId;

  const TransactionDetailsScreen({super.key, required this.txId});

  @override
  ConsumerState<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends ConsumerState<TransactionDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(transactionDetailProvider.notifier).fetchById(widget.txId));
  }

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

  IconData _iconForType(String? type) {
    switch (type) {
      case 'qr_payment':
        return Icons.qr_code_2;
      case 'fd_creation':
        return Icons.account_balance;
      default:
        return Icons.receipt_long;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'qr_payment':
        return const Color(0xFF00704A);
      case 'fd_creation':
        return AppTheme.primaryBlue;
      default:
        return AppTheme.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(transactionDetailProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transaction Details', style: AppTheme.titleMd),
        centerTitle: true,
      ),
      body: _buildBody(detailState),
    );
  }

  Widget _buildBody(TransactionDetailState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: AppTheme.bodySm.copyWith(color: AppTheme.healthHigh)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref
                  .read(transactionDetailProvider.notifier)
                  .fetchById(widget.txId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final tx = state.transaction;
    if (tx == null) {
      return const Center(child: Text('No data'));
    }

    final type = tx['type']?.toString();
    final merchantName = tx['merchant_name']?.toString() ?? 'Unknown';
    final category = tx['merchant_category']?.toString();
    final notes = tx['notes']?.toString();
    final amountUsd = (tx['amount_usd'] as num?)?.toDouble() ?? 0;
    final amountLocal = (tx['amount_local'] as num?)?.toDouble();
    final amountXlm = (tx['amount_xlm'] as num?)?.toDouble();
    final fxRate = (tx['fx_rate'] as num?)?.toDouble();
    final stellarHash = tx['stellar_tx_hash']?.toString();
    final stellarFee = (tx['stellar_fee_xlm'] as num?)?.toDouble();
    final status = (tx['status']?.toString() ?? 'unknown').toUpperCase();
    final createdAt = DateTime.tryParse(tx['created_at']?.toString() ?? '');
    final dateStr = createdAt != null
        ? DateFormat('MMM dd, yyyy • HH:mm z').format(createdAt.toLocal())
        : 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Merchant Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _colorForType(type),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Icon(_iconForType(type),
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                if (category != null && category.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(category,
                        style: AppTheme.caption.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600)),
                  ),
                if (category != null) const SizedBox(height: 8),
                Text(merchantName, style: AppTheme.headlineMd),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(notes, style: AppTheme.caption),
                ],
                const SizedBox(height: 20),

                // Amount
                if (amountLocal != null && type == 'qr_payment') ...[
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: '₹',
                          style:
                              AppTheme.headlineLg.copyWith(fontSize: 20)),
                      TextSpan(
                          text: _fmt(amountLocal).split('.')[0],
                          style:
                              AppTheme.headlineXl.copyWith(fontSize: 42)),
                      TextSpan(
                          text: '.${_fmt(amountLocal).split('.')[1]}',
                          style: AppTheme.headlineXl.copyWith(
                              fontSize: 24,
                              color: AppTheme.textTertiary)),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text('≈ \$${_fmt(amountUsd)} USD',
                      style: AppTheme.bodySm
                          .copyWith(color: AppTheme.primaryBlue)),
                ] else ...[
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: '\$',
                          style:
                              AppTheme.headlineLg.copyWith(fontSize: 20)),
                      TextSpan(
                          text: _fmt(amountUsd).split('.')[0],
                          style:
                              AppTheme.headlineXl.copyWith(fontSize: 42)),
                      TextSpan(
                          text: '.${_fmt(amountUsd).split('.')[1]}',
                          style: AppTheme.headlineXl.copyWith(
                              fontSize: 24,
                              color: AppTheme.textTertiary)),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Detail Cards ──
          _detailCard('Status', status, Icons.check_circle_outline),
          const SizedBox(height: 12),
          _detailCard('Date & Time', dateStr, Icons.schedule),
          const SizedBox(height: 12),
          if (fxRate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _detailCard(
                  'FX Rate', '1 USD = ₹${_fmt(fxRate)}', Icons.trending_up),
            ),
          if (amountXlm != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _detailCard(
                  'XLM Amount', '${amountXlm.toStringAsFixed(7)} XLM', Icons.auto_awesome),
            ),
          if (stellarFee != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _detailCard(
                  'Network Fee', '$stellarFee XLM', Icons.bolt),
            ),
          _detailCard('Payment Method', 'Stellar Credit Line', Icons.credit_card),
          const SizedBox(height: 16),

          // ── Stellar Transaction Hash ──
          if (stellarHash != null && stellarHash.isNotEmpty)
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
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 14, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text('STELLAR TRANSACTION',
                          style: AppTheme.labelUppercase
                              .copyWith(color: AppTheme.primaryBlue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: stellarHash));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Transaction hash copied!')),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${stellarHash.substring(0, stellarHash.length > 12 ? 12 : stellarHash.length)}...${stellarHash.length > 8 ? stellarHash.substring(stellarHash.length - 8) : ''}',
                              style: AppTheme.caption.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy,
                              size: 16, color: AppTheme.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // ── Tags ──
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
                Text('Tags', style: AppTheme.titleSm),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (type == 'qr_payment') _tag('QR Payment'),
                    if (type == 'fd_creation') _tag('Fixed Deposit'),
                    _tag(status),
                    if (category != null) _tag(category),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Action Buttons ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (stellarHash != null) {
                      Clipboard.setData(ClipboardData(text: stellarHash));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hash copied!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Hash'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg)),
                    side: const BorderSide(color: AppTheme.dividerColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg)),
                    side: const BorderSide(color: AppTheme.dividerColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _detailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: AppTheme.caption),
          const Spacer(),
          Flexible(
            child:
                Text(value, style: AppTheme.titleSm, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(label,
          style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
