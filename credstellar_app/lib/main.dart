import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: CredStellarApp()));
}

class CredStellarApp extends StatelessWidget {
  const CredStellarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CredStellar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const _RootScreen(),
    );
  }
}

/// Root screen — checks session, shows auth or app shell.
class _RootScreen extends ConsumerStatefulWidget {
  const _RootScreen();

  @override
  ConsumerState<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<_RootScreen> {
  bool _initialized = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await ref.read(authProvider.notifier).checkSession();
    if (mounted) setState(() => _initialized = true);
  }

  void _navigateToApp() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToApp());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AuthGate(onAuthenticated: _navigateToApp);
  }
}
