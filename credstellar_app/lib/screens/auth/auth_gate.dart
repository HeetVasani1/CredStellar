import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Manages login ↔ signup switching.
/// On success, calls [onAuthenticated] to navigate to the app shell.
class AuthGate extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthGate({super.key, required this.onAuthenticated});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(
        onSwitchToSignup: () => setState(() => _showLogin = false),
        onLoginSuccess: widget.onAuthenticated,
      );
    } else {
      return SignupScreen(
        onSwitchToLogin: () => setState(() => _showLogin = true),
        onSignupSuccess: widget.onAuthenticated,
      );
    }
  }
}
