import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/transaction/customer_balance.dart';
import 'package:hisobnoma/data/models/transaction/inventory_product.dart';
import 'package:hisobnoma/data/models/transaction/sale_detail.dart';
import 'package:hisobnoma/data/models/transaction/unpaid_invoice.dart';
import 'package:hisobnoma/data/models/transaction/sale_record.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/blocs/shift/shift_cubit.dart';
import 'package:hisobnoma/presentation/screens/transactions/add_sale_sheet.dart';
import 'package:hisobnoma/presentation/screens/transactions/shift_sheet.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_empty_state.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_segmented_control.dart';
import 'package:hisobnoma/presentation/widgets/common/loading_shimmer.dart';

enum _TabFilter { inventory, debtors, transactions }

/// Transactions screen with inventory, debtors, and transaction history.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  _TabFilter _activeTab = _TabFilter.inventory;

  @override
  void initState() {
    super.initState();
    context.read<TransactionsCubit>().loadData();
    context.read<ShiftCubit>().loadCurrentShift();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.transactions, style: AppTypography.headline),
        actions: [
          BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, state) {
              final isOpen = state is ShiftLoaded && state.shift.isOpen;
              return IconButton(
                onPressed: () => ShiftSheet.show(context),
                icon: Icon(
                  isOpen ? Icons.access_time_filled : Icons.access_time,
                  color: isOpen ? AppColors.income : AppColors.textSecondary,
                ),
                tooltip: t.shift,
              );
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
                  value: _TabFilter.inventory,
                  label: t.inventory,
                ),
                HisobSegment(
                  value: _TabFilter.debtors,
                  label: t.debtors,
                ),
                HisobSegment(
                  value: _TabFilter.transactions,
                  label: t.transactions,
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
            child: BlocBuilder<TransactionsCubit, TransactionsState>(
              builder: (context, state) {
                if (state is TransactionsLoading) {
                  return const ListShimmer();
                }
                if (state is TransactionsError) {
                  return HisobEmptyState(
                    icon: Icons.error_outline,
                    title: t.error,
                    message: state.message,
                    actionLabel: t.retry,
                    onAction: () =>
                        context.read<TransactionsCubit>().loadData(),
                  );
                }
                if (state is TransactionsDataLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      await context.read<TransactionsCubit>().loadData();
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildTab(state, isDark),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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

  Widget _buildTab(TransactionsDataLoaded state, bool isDark) {
    switch (_activeTab) {
      case _TabFilter.inventory:
        return _InventoryTab(
          key: const ValueKey('inventory'),
          products: state.products,
          isDark: isDark,
        );
      case _TabFilter.debtors:
        return _DebtorsTab(
          key: const ValueKey('debtors'),
          debtors: state.debtors,
          isDark: isDark,
        );
      case _TabFilter.transactions:
        return _TransactionsTab(
          key: const ValueKey('transactions'),
          sales: state.sales,
          isDark: isDark,
        );
    }
  }
}

/// Inventory items list
class _InventoryTab extends StatelessWidget {
  final List<InventoryProduct> products;
  final bool isDark;

  const _InventoryTab({
    super.key,
    required this.products,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    if (products.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          HisobEmptyState(
            icon: Icons.inventory_2_outlined,
            title: t.noInventory,
            message: t.noInventoryHint,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final product = products[index];
        return StaggeredListItem(
          index: index,
          child: _InventoryTile(product: product, isDark: isDark),
        );
      },
    );
  }
}

/// Individual inventory product tile
class _InventoryTile extends StatelessWidget {
  final InventoryProduct product;
  final bool isDark;

  const _InventoryTile({required this.product, required this.isDark});

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
                    if (product.categoryName != null) ...[
                      Text(
                        ' · ',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textTertiary,
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
              if (product.trackInventory)
                Text(
                  '${Formatters.integer(product.stockQuantity.toInt())} ${product.baseUomName}',
                  style: AppTypography.caption2.copyWith(
                    color: product.stockQuantity > 0
                        ? AppColors.income
                        : AppColors.expense,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  product.baseUomName,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Debtors list
class _DebtorsTab extends StatelessWidget {
  final List<CustomerBalance> debtors;
  final bool isDark;

  const _DebtorsTab({
    super.key,
    required this.debtors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    if (debtors.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          HisobEmptyState(
            icon: Icons.person_outline,
            title: t.noDebtors,
            message: t.noDebtorsHint,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: debtors.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final debtor = debtors[index];
        return StaggeredListItem(
          index: index,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => _DebtorDetailSheet(
                  customerId: debtor.customerId,
                  customerName: debtor.customerName,
                  netBalance: debtor.netBalance,
                  isDark: isDark,
                ),
              );
            },
            child: _DebtorTile(debtor: debtor, isDark: isDark),
          ),
        );
      },
    );
  }
}

/// Individual debtor tile
class _DebtorTile extends StatelessWidget {
  final CustomerBalance debtor;
  final bool isDark;

  const _DebtorTile({required this.debtor, required this.isDark});

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
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.expense.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                debtor.customerName.isNotEmpty
                    ? debtor.customerName[0].toUpperCase()
                    : '?',
                style: AppTypography.headline.copyWith(
                  color: AppColors.expense,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Customer details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debtor.customerName,
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
                      debtor.customerCode,
                      style: AppTypography.caption1.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (debtor.lastInvoiceDate != null) ...[
                      Text(
                        ' · ',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        debtor.lastInvoiceDate!,
                        style: AppTypography.caption1.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Balance
          Text(
            Formatters.currency(debtor.netBalance),
            style: AppTypography.subheadline.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

/// Transaction history list
class _TransactionsTab extends StatelessWidget {
  final List<SaleRecord> sales;
  final bool isDark;

  const _TransactionsTab({
    super.key,
    required this.sales,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    if (sales.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          HisobEmptyState(
            icon: Icons.receipt_long_outlined,
            title: t.noTransactions,
            message: t.noTransactionsHint,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final sale = sales[index];
        return StaggeredListItem(
          index: index,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => _TransactionDetailSheet(
                  transactionId: sale.id,
                  isDark: isDark,
                ),
              );
            },
            child: _SaleTile(sale: sale, isDark: isDark),
          ),
        );
      },
    );
  }
}

/// Individual sale transaction tile
class _SaleTile extends StatelessWidget {
  final SaleRecord sale;
  final bool isDark;

  const _SaleTile({required this.sale, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final paymentColor = switch (sale.paymentType) {
      'CREDIT' => AppColors.warning,
      'CARD' => AppColors.royalBlue,
      _ => AppColors.income,
    };

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
          // Payment type icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: paymentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                switch (sale.paymentType) {
                  'CREDIT' => Icons.credit_score,
                  'CARD' => Icons.credit_card,
                  _ => Icons.payments_outlined,
                },
                color: paymentColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customerName ?? sale.transactionNumber,
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
                      Formatters.time(sale.completedAt ?? sale.createdAt),
                      style: AppTypography.caption1.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (sale.cashierName != null) ...[
                      Text(
                        ' · ',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        sale.cashierName!,
                        style: AppTypography.caption1.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (sale.itemCount > 0) ...[
                      Text(
                        ' · ',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '${sale.itemCount} ${t.products.toLowerCase()}',
                        style: AppTypography.caption1.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Amount + payment badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(sale.totalAmount),
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: paymentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sale.paymentType ?? sale.status,
                  style: AppTypography.caption2.copyWith(
                    color: paymentColor,
                    fontWeight: FontWeight.w500,
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

/// Transaction detail bottom sheet — fetches and displays full transaction
class _TransactionDetailSheet extends StatefulWidget {
  final int transactionId;
  final bool isDark;

  const _TransactionDetailSheet({
    required this.transactionId,
    required this.isDark,
  });

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  SaleDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await getIt<TransactionRepository>()
          .getTransactionDetail(widget.transactionId);
      if (mounted) setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkElevated : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.darkSeparator
                    : AppColors.separator,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(t.transactionDetails, style: AppTypography.headline),
          ),
          const Divider(height: 1),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: CircularProgressIndicator.adaptive(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                _error!,
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
            )
          else if (_detail != null)
            Flexible(
              child: _TransactionDetailContent(
                detail: _detail!,
                isDark: widget.isDark,
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionDetailContent extends StatelessWidget {
  final SaleDetail detail;
  final bool isDark;

  const _TransactionDetailContent({
    required this.detail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.transactionNumber,
                      style: AppTypography.title3.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (detail.customerName != null)
                      Text(
                        detail.customerName!,
                        style: AppTypography.subheadline.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (detail.isCompleted
                          ? AppColors.income
                          : AppColors.warning)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  detail.status,
                  style: AppTypography.caption1.copyWith(
                    color: detail.isCompleted
                        ? AppColors.income
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Meta chips
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              if (detail.cashierName != null)
                _MetaChip(icon: Icons.person_outline, label: detail.cashierName!, isDark: isDark),
              if (detail.terminalName != null)
                _MetaChip(icon: Icons.point_of_sale, label: detail.terminalName!, isDark: isDark),
              _MetaChip(icon: Icons.access_time, label: Formatters.time(detail.completedAt ?? detail.createdAt), isDark: isDark),
              _MetaChip(icon: Icons.calendar_today, label: Formatters.shortDate(detail.completedAt ?? detail.createdAt), isDark: isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Line items
          if (detail.lines.isNotEmpty) ...[
            Text(t.items, style: AppTypography.headline.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            )),
            const SizedBox(height: AppSpacing.sm),
            ...detail.lines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LineItemRow(line: line, isDark: isDark),
            )),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Totals
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              children: [
                if (detail.discountAmount > 0)
                  _TotalRow(label: t.discount, value: '-${Formatters.currency(detail.discountAmount)}', color: AppColors.expense, isDark: isDark),
                if (detail.taxAmount > 0)
                  _TotalRow(label: t.tax, value: Formatters.currency(detail.taxAmount), isDark: isDark),
                _TotalRow(label: t.total, value: Formatters.currency(detail.totalAmount), isBold: true, isDark: isDark),
                _TotalRow(label: t.paid, value: Formatters.currency(detail.paidAmount), isDark: isDark),
                if (detail.changeAmount > 0)
                  _TotalRow(label: t.change, value: Formatters.currency(detail.changeAmount), isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Payments
          if (detail.payments.isNotEmpty) ...[
            Text(t.payment, style: AppTypography.headline.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            )),
            const SizedBox(height: AppSpacing.sm),
            ...detail.payments.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    switch (p.paymentType) { 'CREDIT' => Icons.credit_score, 'CARD' => Icons.credit_card, _ => Icons.payments_outlined },
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(p.paymentType, style: AppTypography.subheadline.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  )),
                  const Spacer(),
                  Text(Formatters.currency(p.amount), style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  )),
                ],
              ),
            )),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _MetaChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption1.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        )),
      ],
    );
  }
}

class _LineItemRow extends StatelessWidget {
  final SaleDetailLine line;
  final bool isDark;

  const _LineItemRow({required this.line, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final qtyLabel = line.saleQuantity != null && line.saleUomName != null
        ? '${_fmtQty(line.saleQuantity!)} ${line.saleUomName}'
        : '${_fmtQty(line.quantity)} ${line.uomName ?? ''}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.productName, style: AppTypography.body.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              )),
              Text('$qtyLabel × ${Formatters.currency(line.unitPrice)}',
                style: AppTypography.caption1.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              )),
            ],
          ),
        ),
        Text(Formatters.currency(line.lineTotal), style: AppTypography.subheadline.copyWith(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        )),
      ],
    );
  }

  String _fmtQty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(2);
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  final bool isDark;

  const _TotalRow({required this.label, required this.value, this.isBold = false, this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: (isBold ? AppTypography.headline : AppTypography.subheadline).copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          )),
          Text(value, style: (isBold ? AppTypography.headline : AppTypography.subheadline).copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          )),
        ],
      ),
    );
  }
}

/// Debtor detail bottom sheet — shows unpaid invoices
class _DebtorDetailSheet extends StatefulWidget {
  final int customerId;
  final String customerName;
  final double netBalance;
  final bool isDark;

  const _DebtorDetailSheet({
    required this.customerId,
    required this.customerName,
    required this.netBalance,
    required this.isDark,
  });

  @override
  State<_DebtorDetailSheet> createState() => _DebtorDetailSheetState();
}

class _DebtorDetailSheetState extends State<_DebtorDetailSheet> {
  List<UnpaidInvoice>? _invoices;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final invoices = await getIt<TransactionRepository>()
          .getCustomerUnpaidInvoices(widget.customerId);
      if (mounted) setState(() { _invoices = invoices; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkElevated : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Container(
              width: 36, height: 5,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkSeparator : AppColors.separator,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.customerName.isNotEmpty ? widget.customerName[0].toUpperCase() : '?',
                      style: AppTypography.headline.copyWith(color: AppColors.expense),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.customerName, style: AppTypography.title3.copyWith(
                        color: widget.isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      )),
                      Text(
                        '${t.balanceDue}: ${Formatters.currency(widget.netBalance)}',
                        style: AppTypography.caption1.copyWith(color: AppColors.expense),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: widget.isDark ? AppColors.darkSeparator : AppColors.separator),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: CircularProgressIndicator.adaptive(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(_error!, style: AppTypography.body.copyWith(color: AppColors.error)),
            )
          else if (_invoices != null && _invoices!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Text(t.noUnpaidInvoices, style: AppTypography.subheadline.copyWith(
                color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              )),
            )
          else if (_invoices != null)
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _invoices!.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, index) => _InvoiceCard(
                  invoice: _invoices![index],
                  isDark: widget.isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final UnpaidInvoice invoice;
  final bool isDark;

  const _InvoiceCard({required this.invoice, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: isDark ? null : [
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
          // Invoice header
          Row(
            children: [
              Expanded(
                child: Text(invoice.invoiceNumber, style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                )),
              ),
              if (invoice.overdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.daysOverdueLabel('${invoice.daysOverdue}'),
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Date row
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(invoice.invoiceDate, style: AppTypography.caption1.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              )),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.event, size: 12,
                color: invoice.overdue ? AppColors.error : AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${t.dueDate}: ${invoice.dueDate}', style: AppTypography.caption1.copyWith(
                color: invoice.overdue ? AppColors.error : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              )),
            ],
          ),
          // Line items
          if (invoice.lines.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: isDark ? AppColors.darkSeparator : AppColors.separator),
            const SizedBox(height: AppSpacing.sm),
            ...invoice.lines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(line.productName, style: AppTypography.caption1.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    )),
                  ),
                  Text(
                    '${_fmtQty(line.quantity)} × ${Formatters.currency(line.unitPrice)}',
                    style: AppTypography.caption2.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.balanceDue, style: AppTypography.subheadline.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              )),
              Text(Formatters.currency(invoice.balanceDue), style: AppTypography.headline.copyWith(
                color: AppColors.expense,
              )),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtQty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(2);
}
