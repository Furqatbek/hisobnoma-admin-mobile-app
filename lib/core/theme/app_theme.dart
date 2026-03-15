import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/theme/light_theme.dart';
import 'package:hisobnoma/core/theme/dark_theme.dart';

export 'light_theme.dart';
export 'dark_theme.dart';

/// Central theme configuration for Hisobnoma
abstract final class AppTheme {
  static ThemeData get light => LightTheme.data;
  static ThemeData get dark => DarkTheme.data;

  /// Card decoration with subtle shadow
  static BoxDecoration cardDecoration({
    required bool isDark,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? AppColors.darkCard : AppColors.cardBackground),
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  /// Hero card gradient decoration
  static BoxDecoration heroCardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.royalBlue, AppColors.royalBlueLight],
      ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      boxShadow: [
        BoxShadow(
          color: AppColors.royalBlue.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
