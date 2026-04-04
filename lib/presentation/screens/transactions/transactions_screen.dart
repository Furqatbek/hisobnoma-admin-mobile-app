import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/screens/transactions/add_sale_sheet.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_empty_state.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_segmented_control.dart';
import 'package:hisobnoma/presentation/widgets/common/loading_shimmer.dart';
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
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<TransactionsCubit>().searchProducts(value);
    });
  }

  void _onBarcodePressed() {
    HapticFeedback.lightImpact();
    _showBarcodeDialog();
  }

  Future<void> _showBarcodeDialog() async {
    final t = S.of(context);
    final controller = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.scanBarcode),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: t.barcode,
            prefixIcon: const Icon(Icons.qr_code_scanner, size: 20),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(t.search),
          ),
        ],
      ),
    );
    controller.dispose();
    if (barcode != null && barcode.trim().isNotEmpty && mounted) {
      context.read<TransactionsCubit>().lookupBarcode(barcode.trim());
      setState(() => _activeTab = _TabFilter.products);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField(isDark)
            : Text(t.transactions, style: AppTypography.headline),
        actions: [
          // Barcode scan button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            tooltip: t.scanBarcode,
            onPressed: _onBarcodePressed,
          ),
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
                _debounce?.cancel();
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
              segments: [
                HisobSegment(
                  value: _TabFilter.products,
                  label: t.products,
                ),
                HisobSegment(
                  value: _TabFilter.quickSale,
                  label: t.quickSale,
                ),
                HisobSegment(
                  value: _TabFilter.quickCount,
                  label: t.quickCount,
                ),
              ],
              selectedValue: _activeTab,
              onChanged: (value) {
                setState(() => _activeTab = value);
              },
            ),
          ),

          // Content with animated transition
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildContent(isDark),
            ),
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
    final t = S.of(context);

    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      style: AppTypography.body.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: t.searchProductsHint,
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.textTertiary,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_activeTab) {
      case _TabFilter.products:
        return _ProductsTab(
          key: const ValueKey('products'),
          onAddToSale: (_) => AddSaleSheet.show(context),
        );
      case _TabFilter.quickSale:
        return _QuickSaleTab(key: const ValueKey('quickSale'), isDark: isDark);
      case _TabFilter.quickCount:
        return _QuickCountTab(
            key: const ValueKey('quickCount'), isDark: isDark);
    }
  }
}

/// Products tab — shows search results or browse hint.
class _ProductsTab extends StatelessWidget {
  final ValueChanged<ProductLookup> onAddToSale;

  const _ProductsTab({super.key, required this.onAddToSale});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        if (state is TransactionsLoading) {
          return const ListShimmer();
        }
        // Handle barcode lookup result
        if (state is BarcodeLookupLoaded) {
          final product = state.product;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              StaggeredListItem(
                index: 0,
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
              ),
            ],
          );
        }
        if (state is ProductsSearchLoaded) {
          if (state.products.isEmpty) {
            if (state.query.isEmpty) {
              return HisobEmptyState(
                icon: Icons.inventory_2_outlined,
                title: t.searchProducts,
                message: t.tapSearchToFind,
              );
            }
            return HisobEmptyState(
              icon: Icons.search_off,
              title: t.noResults,
              message: t.noProductsFoundFor(state.query),
            );
          }
          return Column(
            children: [
              // Result count header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Text(
                      t.productsFound('${state.products.length}'),
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    if (state.query.isNotEmpty)
                      Text(
                        '"${state.query}"',
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.royalBlue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.xs,
                  ),
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
                ),
              ),
            ],
          );
        }
        if (state is TransactionsError) {
          return HisobEmptyState(
            icon: Icons.error_outline,
            title: t.error,
            message: state.message,
            actionLabel: t.retry,
            onAction: () =>
                context.read<TransactionsCubit>().searchProducts(''),
          );
        }
        return HisobEmptyState(
          icon: Icons.inventory_2_outlined,
          title: t.products,
          message: t.searchForProducts,
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
    final t = S.of(context);
    final margin = product.sellingPrice - product.costPrice;
    final marginPercent =
        product.costPrice > 0 ? (margin / product.costPrice) * 100 : 0.0;

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

              // Product name + icon
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        product.name.isNotEmpty
                            ? product.name[0].toUpperCase()
                            : '?',
                        style: AppTypography.title2.copyWith(
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTypography.title3.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.sku} · ${product.category}',
                          style: AppTypography.caption1.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Price cards row
              Row(
                children: [
                  Expanded(
                    child: _PriceCard(
                      label: t.sellingPrice,
                      value: Formatters.currency(product.sellingPrice),
                      color: AppColors.income,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PriceCard(
                      label: t.costPrice,
                      value: Formatters.currency(product.costPrice),
                      color: AppColors.expense,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Profit margin card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (margin >= 0 ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color:
                        (margin >= 0 ? AppColors.income : AppColors.expense)
                            .withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      margin >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 18,
                      color: margin >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      t.profitMargin,
                      style: AppTypography.subheadline.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${Formatters.currency(margin)} (${Formatters.percentage(marginPercent)})',
                      style: AppTypography.subheadline.copyWith(
                        fontWeight: FontWeight.w600,
                        color: margin >= 0
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Stock & barcode
              _InfoRow(
                label: t.totalStock,
                value: '${product.totalStock} ${product.uom}',
                isDark: isDark,
              ),
              if (product.barcode.isNotEmpty)
                _InfoRow(
                  label: t.barcode,
                  value: product.barcode,
                  isDark: isDark,
                ),

              // Stock by location
              if (product.stockByLocation.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  t.stockByLocation,
                  style: AppTypography.headline.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...product.stockByLocation.map((loc) => _InfoRow(
                      label: loc.locationName,
                      value: t.availOnHand(
                          '${loc.quantityAvailable}', '${loc.quantityOnHand}'),
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
                  label: Text(t.addToQuickSale),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Price card for product detail sheet
class _PriceCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _PriceCard({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.caption1.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headline.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ],
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

  const _QuickSaleTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

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
          title: t.quickSale,
          message: t.createQuickSaleHint,
          actionLabel: t.newSale,
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
    final t = S.of(context);

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
              child: Text(t.saleCompleted, style: AppTypography.title2),
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
                      label: t.total,
                      value: Formatters.currency(transaction.totalAmount),
                      isBold: true,
                      isDark: isDark,
                    ),
                    _ReceiptRow(
                      label: t.paid,
                      value: Formatters.currency(transaction.paidAmount),
                      isDark: isDark,
                    ),
                    if (transaction.changeAmount > 0)
                      _ReceiptRow(
                        label: t.change,
                        value: Formatters.currency(transaction.changeAmount),
                        isDark: isDark,
                      ),
                    _ReceiptRow(
                      label: t.status,
                      value: transaction.status,
                      color: transaction.isCompleted
                          ? AppColors.income
                          : AppColors.warning,
                      isDark: isDark,
                    ),
                    if (transaction.completedAt != null)
                      _ReceiptRow(
                        label: t.time,
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
                child: Text(t.newSale),
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

  const _QuickCountTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        if (state is QuickCountCompleted) {
          return _QuickCountResult(result: state.result, isDark: isDark);
        }
        return HisobEmptyState(
          icon: Icons.inventory,
          title: t.quickCount,
          message: t.quickCountHint,
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
    final t = S.of(context);

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
                label: t.systemQty,
                value: '${result.systemQuantity}',
                isDark: isDark,
              ),
              _InfoRow(
                label: t.countedQty,
                value: '${result.countedQuantity}',
                isDark: isDark,
              ),
              _InfoRow(
                label: t.variance,
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
