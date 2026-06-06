import 'package:flutter/material.dart';

/// Brand color palette. A calm-but-energetic scheme: deep indigo night sky for
/// surfaces, with a warm "sunrise" accent for primary actions (waking up).
class AppColors {
  AppColors._();

  // Brand seed used to derive the Material 3 color scheme.
  static const Color seed = Color(0xFF5B6CFF);

  // Sunrise accent for primary CTAs (e.g. "Wake up", "Start mission").
  static const Color sunrise = Color(0xFFFF8A4C);

  // Night surfaces (dark theme base).
  static const Color night = Color(0xFF0E1130);
  static const Color nightSurface = Color(0xFF181C3A);

  // Semantic.
  static const Color success = Color(0xFF2FBF71);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFE5484D);
}
