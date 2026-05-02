import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/credit_management/credit_management_screen.dart';
import 'screens/qr_scanner/qr_scanner_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'providers/auth_provider.dart';
import 'providers/credit_provider.dart';
import 'providers/transaction_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/top_app_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CreditManagementScreen(),
    QrScannerScreen(),
    HistoryScreen(),
  ];

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);

    // Refresh data when switching to key tabs
    if (index == 0) {
      // Dashboard — refresh credit
      ref.read(creditProvider.notifier).fetchSummary();
    } else if (index == 3) {
      // History — refresh transactions
      ref.read(transactionListProvider.notifier).fetchTransactions();
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      final nav = Navigator.of(context);
      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (ctx) => AuthGate(
            onAuthenticated: () {
              Navigator.of(ctx).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AppShell()),
                (route) => false,
              );
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isScanner = _currentIndex == 2;

    return Scaffold(
      body: Column(
        children: [
          if (!isScanner) CredStellarAppBar(onLogout: _handleLogout),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: CredStellarBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}
