import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0B0E17);
  static const Color surface = Color(0xFF121624);
  static const Color surfaceElevated = Color(0xFF1A2035);
  static const Color border = Color(0xFF2A324B);

  // Primary accent
  static const Color primary = Color(0xFF818CF8);
  static const Color primaryMuted = Color(0xFF6366F1);

  // Sleep stage colors
  static const Color sleepDeep = Color(0xFF2563EB);
  static const Color sleepLight = Color(0xFF38BDF8);
  static const Color sleepREM = Color(0xFFA855F7);
  static const Color sleepAwake = Color(0xFFF97316);

  // Mom's warmth
  static const Color momWarm = Color(0xFFFCD34D);
  static const Color momCard = Color(0xFF2A2015);
  static const Color momBorder = Color(0xFF4A3520);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Verdict colors (for sleep score ring & banners)
  static Color verdictColor(String? verdict) {
    switch (verdict) {
      case 'good':
        return success;
      case 'okay':
        return primary;
      case 'bad':
        return warning;
      case 'terrible':
        return danger;
      default:
        return primary;
    }
  }

  // Sleep score color (0-100 scale)
  static Color sleepScoreColor(int? score) {
    if (score == null) return textSecondary;
    if (score >= 80) return success;
    if (score >= 60) return primary;
    if (score >= 40) return warning;
    return danger;
  }
}
