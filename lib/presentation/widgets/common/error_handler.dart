import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/error_message.dart';

export 'package:hisobnoma/core/utils/error_message.dart'
    show extractErrorMessage;

/// Shows a floating error snackbar with the backend error message.
void showErrorSnackBar(BuildContext context, Object error) {
  final message = extractErrorMessage(error);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 4),
    ),
  );
}

/// Shows a floating success snackbar.
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      backgroundColor: AppColors.income,
    ),
  );
}

/// Shows a modal error dialog with the backend error message.
Future<void> showErrorDialog(BuildContext context, Object error) {
  final message = extractErrorMessage(error);
  return showDialog(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Error',
              style: AppTypography.headline.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTypography.body.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
