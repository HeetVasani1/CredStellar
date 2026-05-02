import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CredStellar Design System — "The Sovereign Ledger"
/// No 1px borders. Tonal layering. Editorial typography.
class AppTheme {
  // ── Core Colors ──
  static const Color primaryBlue = Color(0xFF3B5BFE);
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color dividerColor = Color(0xFFF3F4F6);

  // ── Status Colors ──
  static const Color statusCleared = Color(0xFF16A34A);
  static const Color statusPending = Color(0xFF3B82F6);
  static const Color statusApproved = Color(0xFF16A34A);
  static const Color statusSystem = Color(0xFF6B7280);
  static const Color amountPositive = Color(0xFF16A34A);
  static const Color amountNegative = Color(0xFF111111);

  // ── Utilization Health ──
  static const Color healthGood = Color(0xFF16A34A);
  static const Color healthCaution = Color(0xFFF59E0B);
  static const Color healthHigh = Color(0xFFEF4444);

  // ── Gradients ──
  static const LinearGradient ctaGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient scanCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows (Ambient only, per DESIGN.md) ──
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];

  // ── Border Radius ──
  static const double radiusXl = 16.0;
  static const double radiusLg = 12.0;
  static const double radiusMd = 8.0;
  static const double radiusSm = 6.0;
  static const double radiusFull = 100.0;

  // ── Spacing ──
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ── Typography ──
  static TextStyle headlineXl = GoogleFonts.manrope(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.1,
  );

  static TextStyle headlineLg = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.2,
  );

  static TextStyle headlineMd = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle headlineSm = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle titleMd = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle titleSm = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textTertiary,
  );

  static TextStyle labelUppercase = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textTertiary,
    letterSpacing: 1.2,
  );

  // ── ThemeData ──
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
          surface: surface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
      );
}
