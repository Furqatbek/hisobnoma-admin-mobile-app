import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';

enum HisobButtonVariant { primary, secondary, text, destructive }

/// Apple HIG-style button with haptic feedback
class HisobButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final HisobButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const HisobButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = HisobButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  });

  const HisobButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  }) : variant = HisobButtonVariant.secondary;

  const HisobButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
  }) : variant = HisobButtonVariant.text;

  const HisobButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  }) : variant = HisobButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);

    void handlePress() {
      HapticFeedback.lightImpact();
      onPressed?.call();
    }

    Widget button;
    switch (variant) {
      case HisobButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : handlePress,
          child: child,
        );
      case HisobButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : handlePress,
          child: child,
        );
      case HisobButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : handlePress,
          child: child,
        );
      case HisobButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: isLoading ? null : handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
          ),
          child: child,
        );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
