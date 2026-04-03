import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';

/// Product list tile used in search results and quick sale.
class ProductTile extends StatelessWidget {
  final ProductLookup product;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Product icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  product.name.isNotEmpty
                      ? product.name[0].toUpperCase()
                      : '?',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        product.sku,
                        style: AppTypography.caption1.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (product.category.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Text(
                            '·',
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            product.category,
                            style: AppTypography.caption1.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Price + stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(product.sellingPrice),
                  style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                _StockBadge(
                  stock: product.totalStock,
                  trackInventory: product.trackInventory,
                ),
              ],
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  final bool trackInventory;

  const _StockBadge({required this.stock, required this.trackInventory});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    if (!trackInventory) {
      return Text(
        t.untracked,
        style: AppTypography.caption2.copyWith(
          color: AppColors.textTertiary,
        ),
      );
    }

    final Color color;
    if (stock <= 0) {
      color = AppColors.error;
    } else if (stock < 10) {
      color = AppColors.warning;
    } else {
      color = AppColors.income;
    }

    return Text(
      t.inStock('$stock'),
      style: AppTypography.caption2.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
