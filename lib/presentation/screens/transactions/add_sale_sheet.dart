import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/constants/uzbekistan_regions.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/screens/transactions/client_selection_sheet.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_segmented_control.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_text_field.dart';
import 'package:hisobnoma/presentation/widgets/transaction/product_tile.dart';

enum _SaleStep { selectClient, addProducts, checkout }

/// Bottom sheet for creating a debt sale.
///
/// Flow: Select client → Add products (qty + price edit) → Checkout (delivery address)
class AddSaleSheet extends StatefulWidget {
  const AddSaleSheet({super.key});

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
  _SaleStep _step = _SaleStep.selectClient;
  Map<String, dynamic>? _selectedClient;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final List<_CartItem> _cart = [];
  String _paymentType = 'DEBT';
  bool _isSubmitting = false;
  String? _selectedRegion;
  String? _selectedArea;

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
            Flexible(child: _buildStepContent(isDark)),
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
    String title;
    switch (_step) {
      case _SaleStep.selectClient:
        title = t.debtSale;
        break;
      case _SaleStep.addProducts:
        title = _cart.isEmpty ? t.debtSale : t.cartCount('${_cart.length}');
        break;
      case _SaleStep.checkout:
        title = t.checkout;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              if (_step == _SaleStep.addProducts) {
                setState(() => _step = _SaleStep.selectClient);
              } else if (_step == _SaleStep.checkout) {
                setState(() => _step = _SaleStep.addProducts);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              _step == _SaleStep.selectClient ? t.cancel : '\u2190 ${t.cancel}',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.headline,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 64),
        ],
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_step) {
      case _SaleStep.selectClient:
        return _buildClientStep(isDark);
      case _SaleStep.addProducts:
        return _buildProductStep(isDark);
      case _SaleStep.checkout:
        return _buildCheckoutStep(isDark);
    }
  }

  // ========== STEP 1: SELECT CLIENT ==========

  Widget _buildClientStep(bool isDark) {
    final t = S.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.clientRequired,
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final client = await ClientSelectionSheet.show(context);
                    if (client != null && mounted) {
                      setState(() {
                        _selectedClient = client;
                        _step = _SaleStep.addProducts;
                      });
                    }
                  },
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(_selectedClient != null
                      ? '${_selectedClient!['name']}'
                      : t.selectClient),
                ),
              ),
            ],
          ),
        ),
        if (_selectedClient != null) ...[
          const Divider(height: 1),
          _buildSelectedClientBanner(isDark),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _step = _SaleStep.addProducts);
                },
                child: Text(t.addMoreItems),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ========== STEP 2: ADD PRODUCTS ==========

  Widget _buildProductStep(bool isDark) {
    final t = S.of(context);
    return Column(
      children: [
        // Selected client banner
        _buildSelectedClientBanner(isDark),
        const Divider(height: 1),
        // Product search
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: HisobTextField(
            controller: _searchController,
            hint: t.searchProductsByNameSku,
            prefixIcon: const Icon(Icons.search, size: 20),
            autofocus: _cart.isEmpty,
            focusNode: _searchFocus,
            onChanged: (value) {
              context.read<TransactionsCubit>().searchProducts(value);
            },
          ),
        ),
        // Cart items (if any)
        if (_cart.isNotEmpty) ...[
          _buildCartSection(isDark),
          // Proceed to checkout button
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.cardBackground,
              border: Border(
                top: BorderSide(
                  color:
                      isDark ? AppColors.darkSeparator : AppColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.total, style: AppTypography.title3),
                      Text(
                        Formatters.currency(_totalAmount),
                        style: AppTypography.title2.copyWith(
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _step = _SaleStep.checkout);
                      },
                      child: Text(
                          '${t.checkout} \u00B7 ${Formatters.currency(_totalAmount)}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Product search results (only when cart is empty or searching)
        if (_cart.isEmpty)
          Expanded(
            child: _buildSearchResults(isDark),
          ),
      ],
    );
  }

  Widget _buildSearchResults(bool isDark) {
    final t = S.of(context);
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        if (state is TransactionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProductsSearchLoaded) {
          if (state.products.isEmpty) {
            return Center(
              child: Text(
                _searchController.text.isEmpty
                    ? t.searchToAdd
                    : t.noProductsFound,
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
            child: Text(state.message,
                style: AppTypography.subheadline
                    .copyWith(color: AppColors.error)),
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(t.searchToAdd,
                  style: AppTypography.subheadline
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartSection(bool isDark) {
    final t = S.of(context);
    return Expanded(
      child: Column(
        children: [
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
                    _searchController.clear();
                    setState(() {});
                    // Show search again by removing focus from cart
                  },
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 18, color: AppColors.royalBlue),
                      const SizedBox(width: AppSpacing.xs),
                      Text(t.addMoreItems,
                          style: AppTypography.subheadline
                              .copyWith(color: AppColors.royalBlue)),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _cart.clear());
                  },
                  child: Text(t.clearAll,
                      style: AppTypography.subheadline
                          .copyWith(color: AppColors.error)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                      padding: const EdgeInsets.only(right: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusCard),
                      ),
                      child:
                          Icon(Icons.delete_outline, color: AppColors.expense),
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
                      onQuantityTap: () => _showQuantityDialog(index),
                      onPriceTap: () => _showPriceDialog(index),
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
        ],
      ),
    );
  }

  // ========== STEP 3: CHECKOUT ==========

  Widget _buildCheckoutStep(bool isDark) {
    final t = S.of(context);
    final areas = _selectedRegion != null
        ? UzbekistanRegions.areasByRegion[_selectedRegion] ?? []
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client info
          _buildSelectedClientBanner(isDark),
          const SizedBox(height: AppSpacing.md),

          // Order summary
          Text(t.orderSummary, style: AppTypography.headline),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(_cart.length, (i) {
            final item = _cart[i];
            final price = item.customPrice ?? item.product.sellingPrice;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.product.name,
                        style: AppTypography.subheadline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${item.quantity} x ${Formatters.currency(price)}',
                      style: AppTypography.caption1
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(Formatters.currency(item.totalPrice),
                      style: AppTypography.subheadline
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.total, style: AppTypography.title3),
              Text(Formatters.currency(_totalAmount),
                  style: AppTypography.title2
                      .copyWith(color: AppColors.royalBlue)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Payment type
          HisobSegmentedControl<String>(
            segments: [
              HisobSegment(value: 'CASH', label: t.cash),
              HisobSegment(value: 'CARD', label: t.card),
              HisobSegment(value: 'DEBT', label: t.debt),
            ],
            selectedValue: _paymentType,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _paymentType = value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Delivery Address
          Text(t.deliveryAddress, style: AppTypography.headline),
          const SizedBox(height: AppSpacing.sm),

          // Region dropdown
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            decoration: InputDecoration(
              labelText: t.region,
              hintText: t.selectRegion,
            ),
            items: UzbekistanRegions.regions
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedRegion = value;
                _selectedArea = null;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Area dropdown
          DropdownButtonFormField<String>(
            value: _selectedArea,
            decoration: InputDecoration(
              labelText: t.area,
              hintText: t.selectArea,
            ),
            items: areas
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: _selectedRegion == null
                ? null
                : (value) {
                    setState(() => _selectedArea = value);
                  },
          ),
          const SizedBox(height: AppSpacing.lg),

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
                  : Text(t.completeSale(Formatters.currency(_totalAmount))),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  // ========== SHARED WIDGETS ==========

  Widget _buildSelectedClientBanner(bool isDark) {
    if (_selectedClient == null) return const SizedBox.shrink();
    final t = S.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.royalBlue.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (_selectedClient!['name'] as String? ?? '?')[0].toUpperCase(),
                style: AppTypography.headline
                    .copyWith(color: AppColors.royalBlue),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.selectedClient}: ${_selectedClient!['name']}',
                  style: AppTypography.subheadline
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (_selectedClient!['phone'] != null)
                  Text(
                    '${_selectedClient!['phone']}',
                    style: AppTypography.caption1
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final client = await ClientSelectionSheet.show(context);
              if (client != null && mounted) {
                setState(() => _selectedClient = client);
              }
            },
            child: Text(
              t.changeClient,
              style: AppTypography.subheadline
                  .copyWith(color: AppColors.royalBlue),
            ),
          ),
        ],
      ),
    );
  }

  // ========== ACTIONS ==========

  void _addToCart(ProductLookup product) {
    HapticFeedback.mediumImpact();
    setState(() {
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

  Future<void> _showQuantityDialog(int index) async {
    final t = S.of(context);
    final item = _cart[index];
    final controller = TextEditingController(text: '${item.quantity}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.enterQuantity),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: t.quantity),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      setState(() {
        _cart[index] = item.copyWith(quantity: result);
      });
    }
  }

  Future<void> _showPriceDialog(int index) async {
    final t = S.of(context);
    final item = _cart[index];
    final currentPrice = item.customPrice ?? item.product.sellingPrice;
    final controller = TextEditingController(text: currentPrice.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.editPrice),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(hintText: t.unitPrice),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      setState(() {
        _cart[index] = item.copyWith(customPrice: result);
      });
    }
  }

  Future<void> _submitSale() async {
    if (_cart.isEmpty || _selectedClient == null) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final request = QuickSaleRequest(
      terminalId: 1,
      customerId: _selectedClient!['id'] as int?,
      customerName: _selectedClient!['name'] as String?,
      items: _cart
          .map((item) => QuickSaleItem(
                productId: item.product.productId,
                quantity: item.quantity.toDouble(),
                unitPrice: item.customPrice ?? item.product.sellingPrice,
              ))
          .toList(),
      paymentType: _paymentType,
      tenderedAmount: _totalAmount,
      deliveryRegion: _selectedRegion,
      deliveryArea: _selectedArea,
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

/// Internal cart item model with editable price.
class _CartItem {
  final ProductLookup product;
  final int quantity;
  final double? customPrice;

  const _CartItem({
    required this.product,
    required this.quantity,
    this.customPrice,
  });

  double get totalPrice =>
      (customPrice ?? product.sellingPrice) * quantity;

  _CartItem copyWith({int? quantity, double? customPrice}) {
    return _CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      customPrice: customPrice ?? this.customPrice,
    );
  }
}

/// Cart item tile with tappable quantity and price.
class _CartItemTile extends StatelessWidget {
  final _CartItem item;
  final bool isDark;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onQuantityTap;
  final VoidCallback onPriceTap;
  final VoidCallback onRemoved;

  const _CartItemTile({
    required this.item,
    required this.isDark,
    required this.onQuantityChanged,
    required this.onQuantityTap,
    required this.onPriceTap,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final price = item.customPrice ?? item.product.sellingPrice;
    final hasCustomPrice = item.customPrice != null;

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
                style:
                    AppTypography.headline.copyWith(color: AppColors.royalBlue),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name + tappable price
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
                GestureDetector(
                  onTap: onPriceTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters.currency(price),
                        style: AppTypography.caption1.copyWith(
                          color: hasCustomPrice
                              ? AppColors.warning
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.edit, size: 10,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tappable quantity stepper
          _QuantityStepper(
            quantity: item.quantity,
            onChanged: onQuantityChanged,
            onTap: onQuantityTap,
            isDark: isDark,
          ),

          const SizedBox(width: AppSpacing.sm),

          // Total + delete
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
                  child: Icon(Icons.delete_outline,
                      size: 16,
                      color: AppColors.error.withValues(alpha: 0.7)),
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
  final VoidCallback onTap;
  final bool isDark;

  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
    required this.onTap,
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
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                '$quantity',
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.royalBlue,
                  decoration: TextDecoration.underline,
                ),
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
