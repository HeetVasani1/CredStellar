import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;

  const StatusBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (label.toUpperCase()) {
      case 'CLEARED':
        bgColor = AppTheme.statusCleared.withValues(alpha: 0.1);
        textColor = AppTheme.statusCleared;
        break;
      case 'APPROVED':
        bgColor = AppTheme.statusApproved.withValues(alpha: 0.1);
        textColor = AppTheme.statusApproved;
        break;
      case 'PENDING':
        bgColor = AppTheme.statusPending.withValues(alpha: 0.1);
        textColor = AppTheme.statusPending;
        break;
      case 'SYSTEM':
        bgColor = AppTheme.statusSystem.withValues(alpha: 0.1);
        textColor = AppTheme.statusSystem;
        break;
      default:
        bgColor = AppTheme.dividerColor;
        textColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
