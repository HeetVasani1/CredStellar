import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToLogin;
  final VoidCallback onSignupSuccess;

  const SignupScreen({
    super.key,
    required this.onSwitchToLogin,
    required this.onSignupSuccess,
  });

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    final success =
        await ref.read(authProvider.notifier).signup(email, password, name);
    if (success && mounted) {
      widget.onSignupSuccess();
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
              Text('Create\nAccount', style: AppTheme.headlineXl),
              const SizedBox(height: 8),
              Text('Start building your FD-backed credit.',
                  style: AppTheme.bodySm),
              const SizedBox(height: 32),

              // ── Error ──
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

              // ── Full Name ──
              Text('FULL NAME', style: AppTheme.labelUppercase),
              const SizedBox(height: 8),
              _inputField(
                controller: _nameController,
                hint: 'John Doe',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // ── Email ──
              Text('EMAIL', style: AppTheme.labelUppercase),
              const SizedBox(height: 8),
              _inputField(
                controller: _emailController,
                hint: 'you@email.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
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
                    hintStyle:
                        AppTheme.bodySm.copyWith(color: AppTheme.textTertiary),
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

              // ── Signup Button ──
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
                    onPressed: authState.isLoading ? null : _handleSignup,
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
                        : Text('Create Account',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Switch to login ──
              Center(
                child: GestureDetector(
                  onTap: widget.onSwitchToLogin,
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: AppTheme.bodySm,
                      children: [
                        TextSpan(
                          text: 'Sign In',
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTheme.titleSm,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.bodySm.copyWith(color: AppTheme.textTertiary),
          prefixIcon: Icon(icon, color: AppTheme.textTertiary, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
