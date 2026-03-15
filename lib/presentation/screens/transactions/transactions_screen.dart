import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/screens/transactions/add_sale_sheet.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_empty_state.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_segmented_control.dart';
import 'package:hisobnoma/presentation/widgets/transaction/product_tile.dart';

enum _TabFilter { products, quickSale, quickCount }

/// Transactions screen with product search and quick actions.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  _TabFilter _activeTab = _TabFilter.products;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField(isDark)
            : Text(AppStrings.transactions, style: AppTypography.headline),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _isSearching = true);
                _searchFocus.requestFocus();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                HapticFeedback.lightImpact();
                _searchController.clear();
                context.read<TransactionsCubit>().reset();
                setState(() => _isSearching = false);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Segmented control
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            child: HisobSegmentedControl<_TabFilter>(
              segments: const [
                HisobSegment(
                  value: _TabFilter.products,
                  label: 'Products',
                ),
                HisobSegment(
                  value: _TabFilter.quickSale,
                  label: 'Quick Sale',
                ),
                HisobSegment(
                  value: _TabFilter.quickCount,
                  label: 'Quick Count',
                ),
              ],
              selectedValue: _activeTab,
              onChanged: (value) {
                setState(() => _activeTab = value);
              },
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(isDark),
          ),
        ],
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () => AddSaleSheet.show(context),
        icon: Icons.point_of_sale,
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      style: AppTypography.body.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.textTertiary,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onChanged: (value) {
        context.read<TransactionsCubit>().searchProducts(value);
      },
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_activeTab) {
      case _TabFilter.products:
        return _ProductsTab(
          onAddToSale: (_) => AddSaleSheet.show(context),
        );
      case _TabFilter.quickSale:
        return _QuickSaleTab(isDark: isDark);
      case _TabFilter.quickCount:
        return _QuickCountTab(isDark: isDark);
    }
  }
}

/// Products tab — shows search results or browse hint.
class _ProductsTab extends StatelessWidget {
  final ValueChanged<ProductLookup> onAddToSale;

  const _ProductsTab({required this.onAddToSale});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        if (state is TransactionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProductsSearchLoaded) {
          if (state.products.isEmpty) {
            if (state.query.isEmpty) {
              return const HisobEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Search Products',
                message:
                    'Tap the search icon to find products by name, SKU, or barcode',
              );
            }
            return HisobEmptyState(
              icon: Icons.search_off,
              title: 'No results',
              message: 'No products found for "${state.query}"',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: state.products.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final product = state.products[index];
              return StaggeredListItem(
                index: index,
                child: ProductTile(
                  product: product,
                  onTap: () => _showProductDetail(context, product),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.add_shopping_cart,
                      size: 20,
                      color: AppColors.royalBlue,
                    ),
                    onPressed: () => onAddToSale(product),
                  ),
                ),
              );
            },
          );
        }
        if (state is TransactionsError) {
          return HisobEmptyState(
            icon: Icons.error_outline,
            title: 'Error',
            message: state.message,
            actionLabel: AppStrings.retry,
            onAction: () =>
                context.read<TransactionsCubit>().searchProducts(''),
          );
        }
        return const HisobEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Products',
          message:
              'Search for products by name, SKU, or scan a barcode',
        );
      },
    );
  }

  void _showProductDetail(BuildContext context, ProductLookup product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        product: product,
        isDark: isDark,
        onAddToSale: () {
          Navigator.of(context).pop();
          onAddToSale(product);
        },
      ),
    );
  }
}

/// Product detail bottom sheet.
class _ProductDetailSheet extends StatelessWidget {
  final ProductLookup product;
  final bool isDark;
  final VoidCallback onAddToSale;

  const _ProductDetailSheet({
    required this.product,
    required this.isDark,
    required this.onAddToSale,
  });

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSeparator
                        : AppColors.separator,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Product name
              Text(
                product.name,
                style: AppTypography.title2.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${product.sku} · ${product.category}',
                style: AppTypography.subheadline.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Price row
              _InfoRow(
                label: 'Selling Price',
                value: Formatters.currency(product.sellingPrice),
                isDark: isDark,
              ),
              _InfoRow(
                label: 'Cost Price',
                value: Formatters.currency(product.costPrice),
                isDark: isDark,
              ),
              _InfoRow(
                label: 'Total Stock',
                value: '${product.totalStock} ${product.uom}',
                isDark: isDark,
              ),
              if (product.barcode.isNotEmpty)
                _InfoRow(
                  label: 'Barcode',
                  value: product.barcode,
                  isDark: isDark,
                ),

              // Stock by location
              if (product.stockByLocation.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Stock by Location',
                  style: AppTypography.headline.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...product.stockByLocation.map((loc) => _InfoRow(
                      label: loc.locationName,
                      value:
                          '${loc.quantityAvailable} avail · ${loc.quantityOnHand} on hand',
                      isDark: isDark,
                    )),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Add to sale button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onAddToSale();
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Add to Quick Sale'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.subheadline.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.subheadline.copyWith(
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Sale tab — recent sales placeholder + create new.
class _QuickSaleTab extends StatelessWidget {
  final bool isDark;

  const _QuickSaleTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        if (state is QuickSaleCompleted) {
          return _SaleReceiptView(
            transaction: state.transaction,
            isDark: isDark,
            onNewSale: () {
              context.read<TransactionsCubit>().reset();
              AddSaleSheet.show(context);
            },
          );
        }
        return HisobEmptyState(
          icon: Icons.point_of_sale,
          title: 'Quick Sale',
          message: 'Create a quick sale by tapping the button below',
          actionLabel: 'New Sale',
          onAction: () => AddSaleSheet.show(context),
        );
      },
    );
  }
}

/// Sale receipt shown after successful sale.
class _SaleReceiptView extends StatelessWidget {
  final QuickSaleResponse transaction;
  final bool isDark;
  final VoidCallback onNewSale;

  const _SaleReceiptView({
    required this.transaction,
    required this.isDark,
    required this.onNewSale,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeScaleIn(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.income,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeScaleIn(
              delay: const Duration(milliseconds: 100),
              child: Text('Sale Completed', style: AppTypography.title2),
            ),
            const SizedBox(height: AppSpacing.sm),
            FadeScaleIn(
              delay: const Duration(milliseconds: 200),
              child: Text(
                transaction.transactionNumber,
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Receipt card
            FadeScaleIn(
              delay: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkCard : AppColors.cardBackground,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    _ReceiptRow(
                      label: 'Total',
                      value: Formatters.currency(transaction.totalAmount),
                      isBold: true,
                      isDark: isDark,
                    ),
                    _ReceiptRow(
                      label: 'Paid',
                      value: Formatters.currency(transaction.paidAmount),
                      isDark: isDark,
                    ),
                    if (transaction.changeAmount > 0)
                      _ReceiptRow(
                        label: 'Change',
                        value: Formatters.currency(transaction.changeAmount),
                        isDark: isDark,
                      ),
                    _ReceiptRow(
                      label: 'Status',
                      value: transaction.status,
                      color: transaction.isCompleted
                          ? AppColors.income
                          : AppColors.warning,
                      isDark: isDark,
                    ),
                    if (transaction.completedAt != null)
                      _ReceiptRow(
                        label: 'Time',
                        value: Formatters.time(transaction.completedAt!),
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            FadeScaleIn(
              delay: const Duration(milliseconds: 400),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onNewSale();
                },
                child: const Text('New Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  final bool isDark;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                (isBold ? AppTypography.headline : AppTypography.subheadline)
                    .copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style:
                (isBold ? AppTypography.headline : AppTypography.subheadline)
                    .copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ??
                  (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Count tab — placeholder for inventory counting.
class _QuickCountTab extends StatelessWidget {
  final bool isDark;

  const _QuickCountTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        if (state is QuickCountCompleted) {
          return _QuickCountResult(result: state.result, isDark: isDark);
        }
        return const HisobEmptyState(
          icon: Icons.inventory,
          title: 'Quick Count',
          message:
              'Search for a product in the Products tab, then perform a stock count',
        );
      },
    );
  }
}

/// Quick count result display.
class _QuickCountResult extends StatelessWidget {
  final QuickCountResponse result;
  final bool isDark;

  const _QuickCountResult({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                result.hasVariance
                    ? Icons.warning_amber_outlined
                    : Icons.check_circle_outline,
                size: 48,
                color:
                    result.hasVariance ? AppColors.warning : AppColors.income,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                result.productName,
                style: AppTypography.title3,
                textAlign: TextAlign.center,
              ),
              Text(
                result.sku,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InfoRow(
                label: 'System Qty',
                value: '${result.systemQuantity}',
                isDark: isDark,
              ),
              _InfoRow(
                label: 'Counted Qty',
                value: '${result.countedQuantity}',
                isDark: isDark,
              ),
              _InfoRow(
                label: 'Variance',
                value:
                    '${result.variance} (${Formatters.percentage(result.variancePercent)})',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
