import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';

/// Apple HIG-style modal bottom sheet with drag handle
class HisobBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final double? maxHeight;

  const HisobBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.maxHeight,
  });

  /// Show the bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    double? maxHeight,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => HisobBottomSheet(
        title: title,
        actions: actions,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight ?? screenHeight * 0.9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSeparator : AppColors.separator,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            // Title bar
            if (title != null || actions != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    if (actions != null && actions!.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(S.of(context).cancel),
                      )
                    else
                      const SizedBox(width: 64),
                    Expanded(
                      child: title != null
                          ? Text(
                              title!,
                              style: AppTypography.headline,
                              textAlign: TextAlign.center,
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (actions != null && actions!.isNotEmpty)
                      actions!.last
                    else
                      const SizedBox(width: 64),
                  ],
                ),
              ),
            const Divider(height: 1),
            // Content
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
