import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/network/api_exceptions.dart';

/// Extracts a user-friendly error message from any exception.
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final dioError = error.error;
    if (dioError is ApiException) {
      return dioError.message;
    }
    // Try to extract message from response body
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return error.message ?? 'Network error';
  }
  if (error is ApiException) {
    return error.message;
  }
  final str = error.toString();
  // Strip "Exception: " prefix if present
  if (str.startsWith('Exception: ')) return str.substring(11);
  return str;
}

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
