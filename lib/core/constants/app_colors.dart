import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — royal blue (from logo's blue flame)
  static const Color primary = Color(0xFF3A7BD5);
  static const Color primaryDark = Color(0xFF2C5FAA);
  static const Color primaryLight = Color(0xFF5B9AE8);

  // Accent — gold yellow (from logo's sunburst + yellow flame)
  static const Color accent = Color(0xFFE8B730);
  static const Color accentDark = Color(0xFFCB9E28);
  static const Color accentLight = Color(0xFFF0CC5E);

  // Flame — warm red (from logo's red flame)
  static const Color flame = Color(0xFFC94040);
  static const Color flameDark = Color(0xFFAA3535);
  static const Color flameLight = Color(0xFFE05A5A);

  // Neutral — deep OLED-optimized darks
  static const Color background = Color(0xFF08080C);
  static const Color surface = Color(0xFF12121C);
  static const Color surfaceVariant = Color(0xFF1C1C2A);
  static const Color onSurface = Color(0xFFE8E6E3);
  static const Color onSurfaceVariant = Color(0xFF9E9E9E);

  // Semantic
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
}
