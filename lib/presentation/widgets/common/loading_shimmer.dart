import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';

/// Shimmer loading placeholder — Apple-style skeleton screens
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppSpacing.radiusSm,
  });

  /// Card-shaped shimmer placeholder
  const LoadingShimmer.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
    this.borderRadius = AppSpacing.radiusCard,
  });

  /// Text-line shaped shimmer placeholder
  const LoadingShimmer.line({
    super.key,
    this.width = 200,
    this.height = 16,
    this.borderRadius = 4,
  });

  /// Circle shimmer (for avatars/icons)
  factory LoadingShimmer.circle({Key? key, double size = 40}) {
    return LoadingShimmer(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkFill : const Color(0xFFE8E8ED),
      highlightColor:
          isDark ? AppColors.darkElevated : const Color(0xFFF5F5F7),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Dashboard shimmer skeleton
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card skeleton
          const LoadingShimmer(height: 140, borderRadius: AppSpacing.radiusLg),
          const SizedBox(height: AppSpacing.md),
          // Summary row
          Row(
            children: [
              const Expanded(
                child: LoadingShimmer(
                    height: 90, borderRadius: AppSpacing.radiusCard),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: LoadingShimmer(
                    height: 90, borderRadius: AppSpacing.radiusCard),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Section header
          const LoadingShimmer.line(width: 150),
          const SizedBox(height: AppSpacing.sm),
          // Inventory row
          Row(
            children: [
              const Expanded(
                child: LoadingShimmer(
                    height: 80, borderRadius: AppSpacing.radiusCard),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: LoadingShimmer(
                    height: 80, borderRadius: AppSpacing.radiusCard),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: LoadingShimmer(
                    height: 80, borderRadius: AppSpacing.radiusCard),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// List item shimmer skeleton
class ListShimmer extends StatelessWidget {
  final int itemCount;

  const ListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            LoadingShimmer(width: 40, height: 40, borderRadius: 20),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingShimmer.line(width: 180),
                  SizedBox(height: AppSpacing.sm),
                  LoadingShimmer.line(width: 120, height: 12),
                ],
              ),
            ),
            LoadingShimmer.line(width: 60),
          ],
        ),
      ),
    );
  }
}
