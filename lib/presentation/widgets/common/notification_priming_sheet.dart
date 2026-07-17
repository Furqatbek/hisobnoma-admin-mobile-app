import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/services/push_notification_service.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';

/// Branded pre-permission sheet shown after the user's first sale, before the
/// iOS system permission dialog. Explains the value so opt-in is a considered
/// choice — tapping "Enable" then triggers the real OS prompt.
class NotificationPrimingSheet extends StatelessWidget {
  final PushNotificationService pushService;

  const NotificationPrimingSheet({super.key, required this.pushService});

  /// Show the sheet if [PushNotificationService.shouldPrimeAfterSale] is true.
  /// Safe to call unconditionally after a sale.
  static void showIfNeeded(
    BuildContext context,
    PushNotificationService pushService,
  ) {
    if (!pushService.shouldPrimeAfterSale) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationPrimingSheet(pushService: pushService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSeparator : AppColors.separator,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 32,
                  color: AppColors.royalBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                t.enableNotificationsTitle,
                style: AppTypography.title3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.enableNotificationsBody,
                style: AppTypography.subheadline.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    pushService.acceptPriming();
                    Navigator.of(context).pop();
                  },
                  child: Text(t.enableNotificationsCta),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    pushService.declinePriming();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    t.notNow,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
