import 'package:flutter/material.dart';

/// Centralized color system for the CashPilot / SoloBytes app.
/// White + Green design language.
class AppColors {
  AppColors._();

  // ── Brand / Primary ──────────────────────────────────────
  static const Color primary       = Color(0xFF2E7D32); // Green 800
  static const Color primaryLight  = Color(0xFF4CAF50); // Green 500
  static const Color primaryDark   = Color(0xFF1B5E20); // Green 900
  static const Color primarySurface = Color(0xFFE8F5E9); // Green 50

  // ── Backgrounds ──────────────────────────────────────────
  static const Color background    = Color(0xFFFFFFFF);
  static const Color surface       = Color(0xFFF8FAF5); // soft green‑tinted
  static const Color scaffoldBg    = Color(0xFFF9FAFB); // faint grey bg

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);

  // ── Borders & Dividers ───────────────────────────────────
  static const Color border        = Color(0xFFE5E7EB);
  static const Color divider       = Color(0xFFF3F4F6);

  // ── Semantic ─────────────────────────────────────────────
  static const Color success       = Color(0xFF16A34A);
  static const Color error         = Color(0xFFDC2626);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color info          = Color(0xFF3B82F6);

  // ── Income / Expense (finance-specific) ──────────────────
  static const Color income        = Color(0xFF16A34A);
  static const Color incomeBg      = Color(0xFFDCFCE7);
  static const Color expense       = Color(0xFFDC2626);
  static const Color expenseBg     = Color(0xFFFEE2E2);

  // ── Ledger ───────────────────────────────────────────────
  static const Color teal          = Color(0xFF0D9488);
  static const Color tealBg        = Color(0xFFCCFBF1);
  static const Color orange        = Color(0xFFF97316);
  static const Color orangeBg      = Color(0xFFFFF7ED);

  // ── Misc ─────────────────────────────────────────────────
  static const Color shadow        = Color(0x0F000000); // ~6 % opacity
  static const Color cardBg        = Colors.white;

  // ── Gradient helpers ─────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGreenGradient = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
