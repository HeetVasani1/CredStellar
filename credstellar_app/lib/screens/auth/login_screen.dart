import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToSignup;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onSwitchToSignup,
    required this.onLoginSuccess,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ref.read(authProvider.notifier).clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).login(email, password);
    if (success && mounted) {
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // ── Brand ──
              Center(
                child: Text('CredStellar',
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    )),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('The Sovereign Ledger',
                    style: AppTheme.bodySm.copyWith(color: AppTheme.textTertiary)),
              ),
              const SizedBox(height: 48),

              // ── Headline ──
              Text('Welcome\nBack', style: AppTheme.headlineXl),
              const SizedBox(height: 8),
              Text('Sign in to access your credit line.',
                  style: AppTheme.bodySm),
              const SizedBox(height: 32),

              // ── Error Message ──
              if (authState.error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.healthHigh.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.healthHigh, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(authState.error!,
                            style: AppTheme.bodySm
                                .copyWith(color: AppTheme.healthHigh)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Email ──
              Text('EMAIL', style: AppTheme.labelUppercase),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTheme.titleSm,
                  decoration: InputDecoration(
                    hintText: 'you@email.com',
                    hintStyle: AppTheme.bodySm.copyWith(color: AppTheme.textTertiary),
                    prefixIcon: const Icon(Icons.mail_outline,
                        color: AppTheme.textTertiary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Password ──
              Text('PASSWORD', style: AppTheme.labelUppercase),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTheme.titleSm,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTheme.bodySm.copyWith(color: AppTheme.textTertiary),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textTertiary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textTertiary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Login Button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: authState.isLoading
                        ? const LinearGradient(
                            colors: [Color(0xFF4A4A5E), Color(0xFF4A4A5E)])
                        : AppTheme.ctaGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXl)),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Sign In',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Switch to signup ──
              Center(
                child: GestureDetector(
                  onTap: widget.onSwitchToSignup,
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: AppTheme.bodySm,
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: AppTheme.titleSm
                              .copyWith(color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
