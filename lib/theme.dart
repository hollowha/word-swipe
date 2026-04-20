import 'package:flutter/material.dart';

abstract class AppTheme {
  // ── Backgrounds ─────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFF1F0ED);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8F7F5);

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF0F0F0F);
  static const Color inkSubtle = Color(0xFF6B6B6B);
  static const Color inkMuted = Color(0xFFBBBBBB);

  // ── Swipe actions ───────────────────────────────────────────────────────────
  static const Color know = Color(0xFF16A34A);
  static const Color learning = Color(0xFFDC2626);

  // ── CEFR palette (muted, sophisticated) ─────────────────────────────────────
  static const Map<String, Color> _cefr = {
    'A1': Color(0xFF7C6AF7),
    'A2': Color(0xFF4A90D9),
    'B1': Color(0xFF2EB06E),
    'B2': Color(0xFFE07C2C),
    'C1': Color(0xFFD24E44),
    'C2': Color(0xFF1A1A1A),
  };

  static Color cefrColor(String level) => _cefr[level] ?? inkSubtle;

  // ── Card decoration ─────────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // ── Typography ──────────────────────────────────────────────────────────────
  static const TextStyle wordDisplay = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: -1.5,
    height: 1.1,
  );

  static const TextStyle phoneticStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: inkSubtle,
    letterSpacing: 0,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: inkMuted,
    letterSpacing: 1.5,
  );

  // ── ThemeData ────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ink,
          brightness: Brightness.light,
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: ink),
        ),
      );
}
