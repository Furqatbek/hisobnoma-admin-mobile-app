import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';

/// Notification count badge (overlays on icons like alert bell)
class HisobBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color? badgeColor;
  final bool show;

  const HisobBadge({
    super.key,
    required this.count,
    required this.child,
    this.badgeColor,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show || count <= 0) return child;

    final displayText = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: AnimatedScale(
            scale: count > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: displayText.length > 1 ? 5 : 4,
                vertical: 1,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.error,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  displayText,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
