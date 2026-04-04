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
import 'package:hisobnoma/presentation/widgets/common/hisob_segmented_control.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_text_field.dart';
import 'package:hisobnoma/presentation/widgets/transaction/product_tile.dart';

/// Bottom sheet for creating a quick sale.
///
/// Flow: Search product → Set quantity → Choose payment → Submit
class AddSaleSheet extends StatefulWidget {
  const AddSaleSheet({super.key});

  /// Shows the add sale bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionsCubit>(),
        child: const AddSaleSheet(),
      ),
    );
  }

  @override
  State<AddSaleSheet> createState() => _AddSaleSheetState();
}

class _AddSaleSheetState extends State<AddSaleSheet> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final List<_CartItem> _cart = [];
  String _paymentType = 'CASH';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      _cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
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
            _buildHandle(isDark),
            _buildHeader(isDark),
            const Divider(height: 1),
            Flexible(
              child: _cart.isEmpty
                  ? _buildProductSearch(isDark)
                  : _buildCartView(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSeparator : AppColors.separator,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final t = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              t.cancel,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _cart.isEmpty ? t.quickSale : t.cartCount('${_cart.length}'),
              style: AppTypography.headline,
              textAlign: TextAlign.center,
            ),
          ),
          if (_cart.isNotEmpty)
            TextButton(
              onPressed: _isSubmitting ? null : _submitSale,
              child: Text(
                t.save,
                style: AppTypography.body.copyWith(
                  color: AppColors.royalBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(width: 64),
        ],
      ),
    );
  }

  // --- Product Search ---

  Widget _buildProductSearch(bool isDark) {
    final t = S.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: HisobTextField(
            controller: _searchController,
            hint: t.searchProductsByNameSku,
            prefixIcon: const Icon(Icons.search, size: 20),
            autofocus: true,
            focusNode: _searchFocus,
            onChanged: (value) {
              context.read<TransactionsCubit>().searchProducts(value);
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<TransactionsCubit, TransactionsState>(
            builder: (context, state) {
              if (state is TransactionsLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is ProductsSearchLoaded) {
                if (state.products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        _searchController.text.isEmpty
                            ? t.searchToAdd
                            : t.noProductsFound,
                        style: AppTypography.subheadline.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: state.products.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ProductTile(
                      product: product,
                      onTap: () => _addToCart(product),
                    );
                  },
                );
              }
              if (state is TransactionsError) {
                return Center(
                  child: Text(
                    state.message,
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                );
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.searchToAdd,
                        style: AppTypography.subheadline.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _addToCart(ProductLookup product) {
    HapticFeedback.mediumImpact();
    setState(() {
      // If already in cart, increase quantity
      final existing = _cart.indexWhere(
        (item) => item.product.productId == product.productId,
      );
      if (existing >= 0) {
        _cart[existing] = _cart[existing].copyWith(
          quantity: _cart[existing].quantity + 1,
        );
      } else {
        _cart.add(_CartItem(product: product, quantity: 1));
      }
    });
  }

  // --- Cart View ---

  Widget _buildCartView(bool isDark) {
    final t = S.of(context);
    return Column(
      children: [
        // Back to search
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {});
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: AppColors.royalBlue,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      t.addMoreItems,
                      style: AppTypography.subheadline.copyWith(
                        color: AppColors.royalBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _cart.clear());
                },
                child: Text(
                  t.clearAll,
                  style: AppTypography.subheadline.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Cart items with swipe-to-delete
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _cart.length,
            itemBuilder: (context, index) {
              final item = _cart[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Dismissible(
                  key: ValueKey(item.product.productId),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    HapticFeedback.mediumImpact();
                    setState(() => _cart.removeAt(index));
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding:
                        const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppColors.expense,
                    ),
                  ),
                  child: _CartItemTile(
                    item: item,
                    isDark: isDark,
                    onQuantityChanged: (qty) {
                      setState(() {
                        if (qty <= 0) {
                          _cart.removeAt(index);
                        } else {
                          _cart[index] = item.copyWith(quantity: qty);
                        }
                      });
                    },
                    onRemoved: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _cart.removeAt(index));
                    },
                  ),
                ),
              );
            },
          ),
        ),

        // Payment type + Total
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.cardBackground,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkSeparator : AppColors.separator,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Payment type
                HisobSegmentedControl<String>(
                  segments: [
                    HisobSegment(value: 'CASH', label: t.cash),
                    HisobSegment(value: 'CARD', label: t.card),
                  ],
                  selectedValue: _paymentType,
                  onChanged: (value) {
                    setState(() => _paymentType = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.total,
                      style: AppTypography.title3.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      Formatters.currency(_totalAmount),
                      style: AppTypography.title2.copyWith(
                        color: AppColors.royalBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitSale,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            t.completeSale(Formatters.currency(_totalAmount))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitSale() async {
    if (_cart.isEmpty) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final request = QuickSaleRequest(
      terminalId: 1,
      items: _cart
          .map((item) => QuickSaleItem(
                productId: item.product.productId,
                quantity: item.quantity,
                unitPrice: item.product.sellingPrice,
              ))
          .toList(),
      paymentType: _paymentType,
      tenderedAmount: _totalAmount,
    );

    try {
      await context.read<TransactionsCubit>().createQuickSale(request);
      if (!mounted) return;

      final t = S.of(context);
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.saleCompletedAmount(Formatters.currency(_totalAmount)),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          backgroundColor: AppColors.income,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final t = S.of(context);
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.failedToCompleteSale),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// Internal cart item model.
class _CartItem {
  final ProductLookup product;
  final int quantity;

  const _CartItem({required this.product, required this.quantity});

  double get totalPrice => product.sellingPrice * quantity;

  _CartItem copyWith({int? quantity}) {
    return _CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Cart item tile with quantity stepper.
class _CartItemTile extends StatelessWidget {
  final _CartItem item;
  final bool isDark;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemoved;

  const _CartItemTile({
    required this.item,
    required this.isDark,
    required this.onQuantityChanged,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: Text(
                item.product.name.isNotEmpty
                    ? item.product.name[0].toUpperCase()
                    : '?',
                style: AppTypography.headline.copyWith(
                  color: AppColors.royalBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name + unit price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Formatters.currency(item.product.sellingPrice),
                  style: AppTypography.caption1.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity stepper
          _QuantityStepper(
            quantity: item.quantity,
            onChanged: onQuantityChanged,
            isDark: isDark,
          ),

          const SizedBox(width: AppSpacing.sm),

          // Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(item.totalPrice),
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: onRemoved,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkFill : AppColors.fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(Icons.remove, () {
            HapticFeedback.selectionClick();
            onChanged(quantity - 1);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '$quantity',
              style: AppTypography.subheadline.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildButton(Icons.add, () {
            HapticFeedback.selectionClick();
            onChanged(quantity + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.royalBlue),
      ),
    );
  }
}
