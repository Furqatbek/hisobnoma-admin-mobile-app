import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/services/push_notification_service.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/core/utils/money.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/widgets/common/notification_priming_sheet.dart';
import 'package:hisobnoma/presentation/blocs/shift/shift_cubit.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/screens/transactions/client_selection_sheet.dart';
import 'package:hisobnoma/presentation/screens/transactions/shift_sheet.dart';
import 'package:hisobnoma/presentation/widgets/common/error_handler.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_segmented_control.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_text_field.dart';

enum _SaleStep { addProducts, checkout }

/// Bottom sheet for creating a sale (cash, card, or debt).
///
/// Flow: Add products (qty + price edit) → Checkout (client + delivery address)
/// Client selection is mandatory only for DEBT payment type.
class AddSaleSheet extends StatefulWidget {
  const AddSaleSheet({super.key});

  /// Shows the sale sheet. Checks for an open shift first.
  /// If no shift is open, opens the ShiftSheet to let the user open one.
  static Future<void> show(BuildContext context) async {
    // Check if there's an open shift
    final shiftCubit = context.read<ShiftCubit>();
    final shiftState = shiftCubit.state;

    if (shiftState is ShiftNone || shiftState is ShiftInitial) {
      // Try to reload shift in case it's stale
      await shiftCubit.loadCurrentShift();
    }

    final currentState = shiftCubit.state;
    final hasOpenShift =
        currentState is ShiftLoaded && currentState.shift.isOpen;

    if (!hasOpenShift) {
      if (!context.mounted) return;
      // Show shift sheet to open a shift first
      final shift = await ShiftSheet.show(context);
      if (shift == null || !shift.isOpen) {
        // User cancelled or shift wasn't opened — show message
        if (context.mounted) {
          final t = S.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.shiftRequired),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TransactionsCubit>()),
          BlocProvider.value(value: context.read<ShiftCubit>()),
        ],
        child: const AddSaleSheet(),
      ),
    );
  }

  @override
  State<AddSaleSheet> createState() => _AddSaleSheetState();
}

class _AddSaleSheetState extends State<AddSaleSheet> {
  _SaleStep _step = _SaleStep.addProducts;
  Map<String, dynamic>? _selectedClient;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final List<_CartItem> _cart = [];
  String _paymentType = 'CASH';
  bool _isSubmitting = false;

  // Terminal
  PosTerminal? _activeTerminal;

  // Products. The initial page is loaded for instant browsing; typing a query
  // triggers a debounced server-side search so items beyond that page are
  // reachable too.
  List<InventoryProduct> _allProducts = [];
  List<InventoryProduct> _filteredProducts = [];
  bool _productsLoading = true;
  bool _searching = false;
  Timer? _searchDebounce;
  bool _showSearch = true; // toggles between search and cart view

  // Delivery address (API-driven)
  List<DeliveryRegion> _regions = [];
  List<DeliveryVillage> _villages = [];
  DeliveryRegion? _selectedRegion;
  DeliveryVillage? _selectedVillage;
  bool _regionsLoading = false;
  bool _villagesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Capture repo reference once — safe to use after awaits
    final repo = context.read<TransactionsCubit>().transactionRepository;

    // Load active terminal
    try {
      final terminals = await repo.getActiveTerminals();
      if (!mounted) return;
      if (terminals.isNotEmpty) {
        setState(() => _activeTerminal = terminals.first);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }

    // Load inventory products
    try {
      final products = await repo.getInventoryProducts(size: 200);
      if (!mounted) return;
      setState(() {
        _allProducts = products.where((p) => p.active).toList();
        _filteredProducts = _allProducts;
        _productsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _productsLoading = false);
      showErrorSnackBar(context, e);
    }

    // Load delivery regions
    if (!mounted) return;
    setState(() => _regionsLoading = true);
    try {
      final regions = await repo.getDeliveryRegions();
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _regionsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _regionsLoading = false);
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _loadVillages(int regionId) async {
    final repo = context.read<TransactionsCubit>().transactionRepository;
    setState(() {
      _villagesLoading = true;
      _villages = [];
      _selectedVillage = null;
    });
    try {
      final villages = await repo.getDeliveryVillages(regionId);
      if (!mounted) return;
      setState(() {
        _villages = villages;
        _villagesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _villagesLoading = false);
      showErrorSnackBar(context, e);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
          children: [
            _buildHandle(isDark),
            _buildHeader(isDark),
            const Divider(height: 1),
            Expanded(child: _buildStepContent(isDark)),
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
      case _SaleStep.addProducts:
        title = _cart.isEmpty ? t.quickSale : t.cartCount('${_cart.length}');
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
              if (_step == _SaleStep.checkout) {
                setState(() => _step = _SaleStep.addProducts);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              _step == _SaleStep.addProducts ? t.cancel : '\u2190 ${t.cancel}',
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
      case _SaleStep.addProducts:
        return _buildProductStep(isDark);
      case _SaleStep.checkout:
        return _buildCheckoutStep(isDark);
    }
  }

  // ========== STEP 1: ADD PRODUCTS ==========

  Widget _buildProductStep(bool isDark) {
    final t = S.of(context);
    final showCartView = _cart.isNotEmpty && !_showSearch;

    return Column(
      children: [
        // Product search field (always visible)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: HisobTextField(
            controller: _searchController,
            hint: t.searchProductsByNameSku,
            prefixIcon: const Icon(Icons.search, size: 20),
            autofocus: _cart.isEmpty,
            focusNode: _searchFocus,
            onChanged: _filterProducts,
            onTap: () {
              if (!_showSearch) setState(() => _showSearch = true);
            },
          ),
        ),

        // Toggle bar when cart has items
        if (_cart.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showSearch = !_showSearch);
                  },
                  child: Row(
                    children: [
                      Icon(
                        _showSearch
                            ? Icons.shopping_cart_outlined
                            : Icons.add_circle_outline,
                        size: 18,
                        color: AppColors.royalBlue,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _showSearch
                            ? t.cartCount('${_cart.length}')
                            : t.addMoreItems,
                        style: AppTypography.subheadline.copyWith(
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!_showSearch)
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
        if (_cart.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        if (_cart.isNotEmpty) const Divider(height: 1),

        // Content: search results or cart
        Expanded(
          child: showCartView
              ? _buildCartList(isDark)
              : _buildSearchResults(isDark),
        ),

        // Bottom bar with total + checkout (when cart has items)
        if (_cart.isNotEmpty)
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
                        '${t.checkout} \u00B7 ${Formatters.currency(_totalAmount)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _filterProducts(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searching = false;
        _filteredProducts = _allProducts;
      });
      return;
    }
    // Instant local matches from the already-loaded page for responsiveness...
    final lower = q.toLowerCase();
    setState(() {
      _searching = true;
      _filteredProducts = _allProducts.where((p) {
        return p.name.toLowerCase().contains(lower) ||
            p.sku.toLowerCase().contains(lower) ||
            p.barcode.toLowerCase().contains(lower);
      }).toList();
    });
    // ...then hit the server (debounced) so items beyond the loaded page are
    // reachable too.
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _runServerSearch(q),
    );
  }

  Future<void> _runServerSearch(String query) async {
    final repo = context.read<TransactionsCubit>().transactionRepository;
    try {
      final result = await repo.searchInventoryProducts(query: query);
      if (!mounted) return;
      // Ignore stale results if the query changed while awaiting.
      if (_searchController.text.trim() != query) return;
      setState(() {
        _filteredProducts = result.content.where((p) => p.active).toList();
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Keep the local matches already shown; just stop the spinner.
      setState(() => _searching = false);
      showErrorSnackBar(context, e);
    }
  }

  Widget _buildSearchResults(bool isDark) {
    final t = S.of(context);

    // Initial load, or a server search with no local matches to show yet.
    if (_productsLoading || (_searching && _filteredProducts.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              _searchController.text.isEmpty
                  ? t.searchToAdd
                  : t.noProductsFound,
              style: AppTypography.subheadline.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _InventoryProductTile(
          product: product,
          isDark: isDark,
          onTap: () => _addToCart(product),
        );
      },
    );
  }

  Widget _buildCartList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _cart.length,
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Dismissible(
            key: ValueKey(item.product.id),
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: Icon(Icons.delete_outline, color: AppColors.expense),
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
    );
  }

  // ========== STEP 2: CHECKOUT ==========

  // The backend POSPaymentType enum uses CREDIT for on-account/debt sales.
  // Sending "DEBT" silently falls back to CASH server-side (marks the sale
  // fully paid and records NO receivable), so the payment value MUST be
  // "CREDIT" for a debt sale.
  static const _creditPaymentType = 'CREDIT';

  bool get _isDebt => _paymentType == _creditPaymentType;
  bool get _clientMissing => _isDebt && _selectedClient == null;

  /// The terminal id of the currently open shift, if any. Sales must be posted
  /// against the shift's terminal, not a hardcoded fallback.
  int? get _openShiftTerminalId {
    final s = context.read<ShiftCubit>().state;
    if (s is ShiftLoaded && s.shift.isOpen) return s.shift.terminalId;
    if (s is ShiftOpened) return s.shift.terminalId;
    return null;
  }

  Widget _buildCheckoutStep(bool isDark) {
    final t = S.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment type (moved to top so DEBT triggers client requirement)
          HisobSegmentedControl<String>(
            segments: [
              HisobSegment(value: 'CASH', label: t.cash),
              HisobSegment(value: 'CARD', label: t.card),
              HisobSegment(value: _creditPaymentType, label: t.debt),
            ],
            selectedValue: _paymentType,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _paymentType = value);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Client selection — required for DEBT, optional for CASH/CARD
          if (_selectedClient != null)
            _buildSelectedClientBanner(isDark)
          else
            _buildSelectClientButton(isDark),
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
                    child: Text(
                      item.product.name,
                      style: AppTypography.subheadline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${formatQuantity(item.quantity)} x ${Formatters.currency(price)}',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    Formatters.currency(item.totalPrice),
                    style: AppTypography.subheadline.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
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
          const SizedBox(height: AppSpacing.lg),

          // Delivery Address
          Text(t.deliveryAddress, style: AppTypography.headline),
          const SizedBox(height: AppSpacing.sm),

          // Region dropdown (API-driven)
          DropdownButtonFormField<DeliveryRegion>(
            value: _selectedRegion,
            decoration: InputDecoration(
              labelText: t.region,
              hintText: t.selectRegion,
              suffixIcon: _regionsLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            items: _regions
                .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedRegion = value;
                _selectedVillage = null;
                _villages = [];
              });
              if (value != null) {
                _loadVillages(value.id);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Area/Village dropdown (API-driven, filtered by region)
          DropdownButtonFormField<DeliveryVillage>(
            value: _selectedVillage,
            decoration: InputDecoration(
              labelText: t.area,
              hintText: t.selectArea,
              suffixIcon: _villagesLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            items: _villages
                .map((v) => DropdownMenuItem(value: v, child: Text(v.name)))
                .toList(),
            onChanged: _selectedRegion == null
                ? null
                : (value) {
                    setState(() => _selectedVillage = value);
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

  Widget _buildSelectClientButton(bool isDark) {
    final t = S.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: _clientMissing
            ? Border.all(color: AppColors.error, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_clientMissing)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                t.clientRequired,
                style: AppTypography.caption1.copyWith(color: AppColors.error),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final client = await ClientSelectionSheet.show(context);
                if (client != null && mounted) {
                  setState(() => _selectedClient = client);
                }
              },
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: Text(t.selectClient),
              style: OutlinedButton.styleFrom(
                foregroundColor: _clientMissing
                    ? AppColors.error
                    : AppColors.royalBlue,
                side: BorderSide(
                  color: _clientMissing
                      ? AppColors.error
                      : AppColors.royalBlue.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                style: AppTypography.headline.copyWith(
                  color: AppColors.royalBlue,
                ),
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
                  style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedClient!['phone'] != null)
                  Text(
                    '${_selectedClient!['phone']}',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
              style: AppTypography.subheadline.copyWith(
                color: AppColors.royalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== ACTIONS ==========

  void _addToCart(InventoryProduct product) {
    HapticFeedback.mediumImpact();
    setState(() {
      final existing = _cart.indexWhere(
        (item) => item.product.id == product.id,
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
    final controller = TextEditingController(
      text: formatQuantity(item.quantity),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.enterQuantity),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(hintText: t.quantity),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
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
    final controller = TextEditingController(
      text: currentPrice.toStringAsFixed(0),
    );
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
      // Enforce the product's price floor when the backend provides one.
      final floor = item.product.minSellingPrice;
      if (floor > 0 && result < floor) {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.unitPrice} ≥ ${Formatters.currency(floor)}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() {
        _cart[index] = item.copyWith(customPrice: result);
      });
    }
  }

  Future<void> _submitSale() async {
    if (_cart.isEmpty || _isSubmitting) return;

    // Client is required for DEBT sales
    if (_isDebt && _selectedClient == null) {
      HapticFeedback.heavyImpact();
      setState(() {}); // trigger rebuild to show error border
      final t = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.selectClientFirst),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Post the sale against the OPEN SHIFT's terminal — never a hardcoded
    // fallback. If we cannot resolve it, block the sale rather than silently
    // recording it against the wrong terminal.
    final terminalId = _openShiftTerminalId ?? _activeTerminal?.id;
    if (terminalId == null) {
      HapticFeedback.heavyImpact();
      final t = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.shiftRequired),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final cubit = context.read<TransactionsCubit>();
    final total = _totalAmount;
    try {
      final request = QuickSaleRequest(
        terminalId: terminalId,
        // Null-safe: client is optional for CASH/CARD sales.
        customerId: _selectedClient?['id'] as int?,
        customerName: _selectedClient?['name'] as String?,
        items: _cart
            .map(
              (item) => QuickSaleItem(
                productId: item.product.id,
                quantity: item.quantity,
                // Round to a fixed money scale to avoid IEEE double drift.
                unitPrice: roundMoney(
                  item.customPrice ?? item.product.sellingPrice,
                ),
              ),
            )
            .toList(),
        paymentType: _paymentType,
        // For CREDIT (debt), tender 0 so nothing is settled — the backend
        // records the full amount as a receivable. Cash/card tender the total.
        tenderedAmount: _isDebt ? 0.0 : roundMoney(total),
        deliveryRegionId: _selectedRegion?.id,
        deliveryVillageId: _selectedVillage?.id,
        // Idempotency key: one per sale attempt. A timed-out sale is safely
        // auto-retried with the same key and the backend dedups on it, so a
        // lost response can never create a duplicate sale.
        clientRequestId: Uuid().v4(),
      );

      // Call the repository directly so a failed sale actually throws and
      // lands in the catch below — never a false "completed" confirmation.
      await cubit.transactionRepository.quickSale(request);
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      // Refresh the transactions screen so the new sale appears and the
      // screen behind the sheet is not left blank.
      unawaited(cubit.loadData());

      final t = S.of(context);
      // Capture the app-level navigator context before popping the sheet, so
      // the after-sale notification priming can be shown on a context that
      // survives this sheet's disposal.
      final rootContext = Navigator.of(context, rootNavigator: true).context;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.saleCompletedAmount(Formatters.currency(total))),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          backgroundColor: AppColors.income,
        ),
      );

      // After the user's first sale, gently ask to turn on notifications
      // (no-op if already asked or the user opted out). Deferred a frame so it
      // opens after the sheet finishes closing.
      final pushService = getIt<PushNotificationService>();
      if (pushService.shouldPrimeAfterSale) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (rootContext.mounted) {
            NotificationPrimingSheet.showIfNeeded(rootContext, pushService);
          }
        });
      }
    } catch (e) {
      // Sale failed: keep the sheet open with the cart intact and show the
      // real backend error so the cashier does not hand over unpaid goods.
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      // Always release the button, on every exit path.
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// Internal cart item model with editable price and fractional quantity.
class _CartItem {
  final InventoryProduct product;
  final double quantity;
  final double? customPrice;

  const _CartItem({
    required this.product,
    required this.quantity,
    this.customPrice,
  });

  double get totalPrice => (customPrice ?? product.sellingPrice) * quantity;

  _CartItem copyWith({double? quantity, double? customPrice}) {
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
  final ValueChanged<double> onQuantityChanged;
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
                style: AppTypography.headline.copyWith(
                  color: AppColors.royalBlue,
                ),
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
                      Icon(
                        Icons.edit,
                        size: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
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
  final double quantity;
  final ValueChanged<double> onChanged;
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                formatQuantity(quantity),
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

/// Product tile for inventory products in search results.
class _InventoryProductTile extends StatelessWidget {
  final InventoryProduct product;
  final bool isDark;
  final VoidCallback onTap;

  const _InventoryProductTile({
    required this.product,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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
                      if (product.categoryName != null &&
                          product.categoryName!.isNotEmpty) ...[
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
                            product.categoryName!,
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
                Text(
                  '${product.stockQuantity.toInt()}',
                  style: AppTypography.caption2.copyWith(
                    color: product.stockQuantity <= 0
                        ? AppColors.error
                        : product.stockQuantity < 10
                        ? AppColors.warning
                        : AppColors.income,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
