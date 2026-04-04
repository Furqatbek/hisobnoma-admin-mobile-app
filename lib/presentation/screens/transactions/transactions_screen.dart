import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/transaction/customer_balance.dart';
import 'package:hisobnoma/data/models/transaction/inventory_product.dart';
import 'package:hisobnoma/data/models/transaction/sale_record.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/screens/transactions/add_sale_sheet.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.transactions, style: AppTypography.headline),
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
          child: _DebtorTile(debtor: debtor, isDark: isDark),
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
          child: _SaleTile(sale: sale, isDark: isDark),
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
    final statusColor =
        sale.isCompleted ? AppColors.income : AppColors.warning;
    final statusLabel = sale.isCompleted ? t.completed : t.pending;

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
          // Status icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                sale.isCompleted
                    ? Icons.check_circle_outline
                    : Icons.schedule,
                color: statusColor,
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
                  sale.transactionNumber,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (sale.customerName != null &&
                        sale.customerName!.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          sale.customerName!,
                          style: AppTypography.caption1.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                    Text(
                      Formatters.relativeDate(sale.createdAt),
                      style: AppTypography.caption1.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Amount + status
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
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.caption2.copyWith(
                    color: statusColor,
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
