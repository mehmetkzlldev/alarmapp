import 'package:flutter/material.dart';

/// "Mango Sunrise" — a bright, gradient-forward LIGHT palette. Warm cream
/// surfaces with an orange→pink brand gradient and a sunny-yellow accent.
class AppColors {
  AppColors._();

  // Brand primary (vivid orange) — drives the Material 3 color scheme.
  static const Color seed = Color(0xFFFF6A3D);

  // Brand gradient endpoints (orange → pink).
  static const Color gradientStart = Color(0xFFFF512F);
  static const Color gradientEnd = Color(0xFFFF6FD8);

  // Secondary + accent.
  static const Color pink = Color(0xFFFF4D9D);
  static const Color accent = Color(0xFFFFD93D); // sunny yellow

  // Back-compat alias (the old "sunrise" accent) — now the brand orange.
  static const Color sunrise = Color(0xFFFF6A3D);

  // Light surfaces.
  static const Color cream = Color(0xFFFFF7ED); // warm cream background
  static const Color creamDeep = Color(0xFFFFE8D6); // soft peach (bg gradient)
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color ink = Color(0xFF2A1A12); // warm dark text

  // Dark fallback (theme defaults to light, so rarely used).
  static const Color night = Color(0xFF1A1020);
  static const Color nightSurface = Color(0xFF261830);

  // Semantic.
  static const Color success = Color(0xFF2FBF71);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFE5484D);

  /// The signature orange→pink brand gradient (buttons, headers, highlights).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  /// Subtle light background gradient (cream → peach).
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cream, creamDeep],
  );
}
