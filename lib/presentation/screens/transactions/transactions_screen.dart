import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/sync/sync_models.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/screens/transactions/add_sale_sheet.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_empty_state.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_segmented_control.dart';
import 'package:hisobnoma/presentation/widgets/common/loading_shimmer.dart';

enum _TabFilter { inventory, debtors, creditors }

/// Transactions screen with inventory, debtors, and creditors lists.
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
                  value: _TabFilter.creditors,
                  label: t.creditors,
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
        return _CustomersTab(
          key: const ValueKey('debtors'),
          customers: state.debtors,
          isDebtor: true,
          isDark: isDark,
        );
      case _TabFilter.creditors:
        return _CustomersTab(
          key: const ValueKey('creditors'),
          customers: state.creditors,
          isDebtor: false,
          isDark: isDark,
        );
    }
  }
}

/// Inventory items list
class _InventoryTab extends StatelessWidget {
  final List<SyncProduct> products;
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
  final SyncProduct product;
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
          // Price
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
                product.unitOfMeasure,
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

/// Debtors / Creditors list
class _CustomersTab extends StatelessWidget {
  final List<SyncCustomer> customers;
  final bool isDebtor;
  final bool isDark;

  const _CustomersTab({
    super.key,
    required this.customers,
    required this.isDebtor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    if (customers.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          HisobEmptyState(
            icon: isDebtor
                ? Icons.person_outline
                : Icons.business_outlined,
            title: isDebtor ? t.noDebtors : t.noCreditors,
            message: isDebtor ? t.noDebtorsHint : t.noCreditorsHint,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return StaggeredListItem(
          index: index,
          child: _CustomerTile(
            customer: customer,
            isDebtor: isDebtor,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

/// Individual customer tile for debtors/creditors
class _CustomerTile extends StatelessWidget {
  final SyncCustomer customer;
  final bool isDebtor;
  final bool isDark;

  const _CustomerTile({
    required this.customer,
    required this.isDebtor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final balanceColor = isDebtor ? AppColors.expense : AppColors.income;
    final absBalance = customer.currentBalance.abs();

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
              color: balanceColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                customer.name.isNotEmpty
                    ? customer.name[0].toUpperCase()
                    : '?',
                style: AppTypography.headline.copyWith(
                  color: balanceColor,
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
                  customer.name,
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
                      customer.code,
                      style: AppTypography.caption1.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (customer.phone != null) ...[
                      Text(
                        ' · ',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          customer.phone!,
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
          // Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(absBalance),
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: balanceColor,
                ),
              ),
              if (customer.creditLimit > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${t.creditLimit}: ${Formatters.compactCurrency(customer.creditLimit)}',
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
