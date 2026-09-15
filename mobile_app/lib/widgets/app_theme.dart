import 'package:flutter/material.dart';

/// ─── SIMHPSK Design Tokens (Figma palette) ──────────────────────────────────
class AppTheme {
  AppTheme._();

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color sidebarBg          = Color(0xFF1B2E22);
  static const Color sidebarBgCollapsed = Color(0xFF152419);
  static const Color sidebarActiveItem  = Color(0xFF2D6A4F);
  static const Color sidebarActiveBg    = Color(0xFF243D2F);
  static const Color sidebarText        = Color(0xFF8BAF9A);
  static const Color sidebarTextActive  = Color(0xFFFFFFFF);
  static const Color sidebarDivider     = Color(0xFF253D2E);

  static const Color pageBg             = Color(0xFFF0F4F1);
  static const Color cardBg             = Color(0xFFFFFFFF);
  static const Color cardBorder         = Color(0xFFE8EDE9);

  static const Color textPrimary        = Color(0xFF111827);
  static const Color textSecondary      = Color(0xFF6B7280);
  static const Color textMuted          = Color(0xFF9CA3AF);

  static const Color green900           = Color(0xFF1B4332);
  static const Color green700           = Color(0xFF2D6A4F);
  static const Color green500           = Color(0xFF52B788);
  static const Color green300           = Color(0xFF95D5B2);
  static const Color green100           = Color(0xFFD8F3DC);

  static const Color amber600           = Color(0xFFD97706);
  static const Color amber100           = Color(0xFFFEF3C7);

  static const Color blue600            = Color(0xFF1D4ED8);
  static const Color blue100            = Color(0xFFDBEAFE);

  static const Color red600             = Color(0xFFDC2626);
  static const Color red100             = Color(0xFFFFE4E6);

  static const Color purple600          = Color(0xFF7C3AED);
  static const Color purple100         = Color(0xFFEDE9FE);

  // ── Banner gradient ────────────────────────────────────────────────────────
  static const List<Color> bannerGradient = [
    Color(0xFF1B4332),
    Color(0xFF2D6A4F),
    Color(0xFF40916C),
  ];

  // ── Typography ─────────────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5);
  static const TextStyle h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary);
  static const TextStyle h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary);
  static const TextStyle caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted);
  static const TextStyle labelBold = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary);

  // ── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> get sidebarShadow => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(4, 0)),
  ];

  static List<BoxShadow> get floatShadow => [
    BoxShadow(color: green700.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
  ];

  // ── Radius ─────────────────────────────────────────────────────────────────
  static const Radius r4   = Radius.circular(4);
  static const Radius r8   = Radius.circular(8);
  static const Radius r12  = Radius.circular(12);
  static const Radius r16  = Radius.circular(16);
  static const Radius r20  = Radius.circular(20);
  static const Radius r24  = Radius.circular(24);

  static const BorderRadius card = BorderRadius.all(r16);
  static const BorderRadius btn  = BorderRadius.all(r12);
  static const BorderRadius chip = BorderRadius.all(r20);
  static const BorderRadius tag  = BorderRadius.all(r8);

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double sidebarExpandedW  = 260.0;
  static const double sidebarCollapsedW = 72.0;
  static const double headerH           = 68.0;
  static const double pageHPad          = 28.0;
  static const double pageVPad          = 24.0;
  static const double cardGap           = 16.0;
}
