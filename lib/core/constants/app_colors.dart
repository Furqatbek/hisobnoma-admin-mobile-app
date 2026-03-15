import 'package:flutter/material.dart';

/// Hisobnoma color system — Apple HIG compliant
abstract final class AppColors {
  // Primary
  static const Color royalBlue = Color(0xFF1E3A8A);
  static const Color royalBlueLight = Color(0xFF2B4FCF);
  static const Color royalBlueDark = Color(0xFF152C6B);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFAEAEB2);
  static const Color separator = Color(0xFFE5E5EA);
  static const Color fill = Color(0xFFF2F2F7);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF3B30);
  static const Color income = Color(0xFF34C759);
  static const Color expense = Color(0xFFFF3B30);

  // Dark mode
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkElevated = Color(0xFF2C2C2E);
  static const Color darkSeparator = Color(0xFF38383A);
  static const Color darkFill = Color(0xFF1C1C1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
}
