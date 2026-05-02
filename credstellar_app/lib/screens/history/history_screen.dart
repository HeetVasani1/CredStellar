import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/status_badge.dart';
import '../transaction_details/transaction_details_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(transactionListProvider.notifier).fetchTransactions());
  }

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

  /// Group transactions by date label (TODAY, YESTERDAY, or formatted date)
  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> txns) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in txns) {
      final createdAt = DateTime.tryParse(tx['created_at']?.toString() ?? '');
      String label;
      if (createdAt == null) {
        label = 'UNKNOWN';
      } else {
        final txDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
        if (txDate == today) {
          label = 'TODAY';
        } else if (txDate == yesterday) {
          label = 'YESTERDAY';
        } else {
          label = DateFormat('MMM dd, yyyy').format(createdAt).toUpperCase();
        }
      }
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(tx);
    }
    return grouped;
  }

  /// Filter transactions by type
  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> txns) {
    if (_activeFilter == 'All') return txns;
    if (_activeFilter == 'Payments') {
      return txns.where((t) => t['type'] == 'qr_payment').toList();
    }
    if (_activeFilter == 'FD') {
      return txns.where((t) => t['type'] == 'fd_creation').toList();
    }
    return txns;
  }

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

  String _channelForType(String? type) {
    switch (type) {
      case 'qr_payment':
        return 'QR Payment';
      case 'fd_creation':
        return 'Fixed Deposit';
      default:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionListProvider);
    final filtered = _applyFilter(txState.transactions);
    final grouped = _groupByDate(filtered);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(transactionListProvider.notifier).fetchTransactions(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('The Ledger', style: AppTheme.headlineLg),
            const SizedBox(height: 4),
            Text('Your secure transaction history across all currencies.',
                style: AppTheme.bodySm),
            const SizedBox(height: 20),

            // ── Filter Chips ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All'),
                  const SizedBox(width: 8),
                  _filterChip('Payments'),
                  const SizedBox(width: 8),
                  _filterChip('FD'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Loading ──
            if (txState.isLoading) ...[
              const SizedBox(height: 60),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 60),
            ]

            // ── Error ──
            else if (txState.error != null) ...[
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
                    Text(txState.error!,
                        style: AppTheme.bodySm
                            .copyWith(color: AppTheme.healthHigh)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref
                          .read(transactionListProvider.notifier)
                          .fetchTransactions(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ]

            // ── Empty ──
            else if (filtered.isEmpty) ...[
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long,
                        color: AppTheme.textTertiary, size: 48),
                    const SizedBox(height: 12),
                    Text('No transactions yet', style: AppTheme.titleSm),
                    const SizedBox(height: 4),
                    Text('Make a payment or create an FD to see activity.',
                        style: AppTheme.caption),
                  ],
                ),
              ),
            ]

            // ── Transaction list grouped by date ──
            else
              ...grouped.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: AppTheme.labelUppercase),
                      const SizedBox(height: 12),
                      ...entry.value.map((tx) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _txTile(tx),
                          )),
                      const SizedBox(height: 12),
                    ],
                  )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryDark : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: isActive ? [] : AppTheme.cardShadow,
        ),
        child: Text(
          label,
          style: AppTheme.titleSm.copyWith(
            color: isActive ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _txTile(Map<String, dynamic> tx) {
    final type = tx['type']?.toString();
    final isPayment = type == 'qr_payment';
    final merchantName = tx['merchant_name']?.toString() ?? 'Unknown';
    final amountUsd = (tx['amount_usd'] as num?)?.toDouble() ?? 0;
    final amountLocal = (tx['amount_local'] as num?)?.toDouble();
    final amountXlm = (tx['amount_xlm'] as num?)?.toDouble();
    final status = (tx['status']?.toString() ?? 'unknown').toUpperCase();
    final createdAt = DateTime.tryParse(tx['created_at']?.toString() ?? '');
    final timeStr =
        createdAt != null ? DateFormat('hh:mm a').format(createdAt.toLocal()) : '';
    final txId = tx['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (txId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailsScreen(txId: txId),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
                color: isPayment
                    ? AppTheme.dividerColor
                    : AppTheme.healthGood.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(_iconForType(type),
                  color: isPayment
                      ? AppTheme.textSecondary
                      : AppTheme.healthGood,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(merchantName,
                      style: AppTheme.titleSm,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$timeStr  •  ${_channelForType(type)}',
                      style: AppTheme.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPayment ? '-' : '+'}\$${_fmt(amountUsd)}',
                  style: AppTheme.titleSm.copyWith(
                    color: isPayment
                        ? AppTheme.textPrimary
                        : AppTheme.amountPositive,
                  ),
                ),
                if (amountLocal != null && isPayment) ...[
                  const SizedBox(height: 2),
                  Text('₹${_fmt(amountLocal)}',
                      style: AppTheme.caption.copyWith(fontSize: 11)),
                ],
                if (amountXlm != null && amountXlm > 0) ...[
                  const SizedBox(height: 2),
                  Text('${amountXlm.toStringAsFixed(4)} XLM',
                      style: AppTheme.caption.copyWith(fontSize: 11)),
                ],
                const SizedBox(height: 4),
                StatusBadge(label: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
