import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/router/app_router.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:hisobnoma/data/models/dashboard/dashboard_models.dart';
import 'package:hisobnoma/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:hisobnoma/presentation/widgets/charts/revenue_line_chart.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_badge.dart';
import 'package:hisobnoma/presentation/screens/transactions/add_sale_sheet.dart';
import 'package:hisobnoma/presentation/widgets/common/loading_shimmer.dart';

/// Main dashboard / home screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
    context.read<AlertsCubit>().loadUnreadCount();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName, style: AppTypography.headline),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: BlocBuilder<AlertsCubit, AlertsState>(
              builder: (context, alertState) {
                final count = _unreadCount(alertState);
                return IconButton(
                  icon: HisobBadge(
                    count: count,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push(AppRoutes.alerts);
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const DashboardShimmer();
          }
          if (state is DashboardError) {
            return _buildErrorState(state);
          }
          if (state is DashboardLoaded) {
            return _buildLoadedContent(state, isDark);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () => AddSaleSheet.show(context),
        icon: Icons.point_of_sale,
      ),
    );
  }

  int _unreadCount(AlertsState state) {
    if (state is AlertsLoaded) return state.unreadCount;
    if (state is AlertsUnreadCountLoaded) return state.count;
    return 0;
  }

  Widget _buildErrorState(DashboardError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load dashboard',
              style: AppTypography.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.message,
              style: AppTypography.subheadline.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () =>
                  context.read<DashboardCubit>().loadDashboard(),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(DashboardLoaded state, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await context.read<DashboardCubit>().refresh();
        if (mounted) {
          context.read<AlertsCubit>().loadUnreadCount();
        }
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Greeting + last updated
          FadeScaleIn(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _greeting,
                    style: AppTypography.title2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (state.lastUpdated != null)
                  Text(
                    Formatters.time(state.lastUpdated!),
                    style: AppTypography.caption2.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),

          // Partial error banner
          if (state.partialErrors != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _PartialErrorBanner(
              errors: state.partialErrors!,
              isDark: isDark,
              onRetry: () => context.read<DashboardCubit>().refresh(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Hero balance card
          FadeScaleIn(
            delay: const Duration(milliseconds: 80),
            child: _BalanceHeroCard(
              balance: state.financial.netCashPosition,
              changePercent: state.revenue.monthChangePercent,
              todayRevenue: state.revenue.todayRevenue,
              transactionCount: state.revenue.todayTransactionCount,
              weekRevenue: state.revenue.thisWeekRevenue,
              weekTransactions: state.revenue.thisWeekTransactionCount,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Revenue / Expenses summary pills
          FadeScaleIn(
            delay: const Duration(milliseconds: 160),
            child: _SummaryPillRow(
              revenue: state.revenue.thisMonthRevenue,
              revenueChange: state.revenue.monthChangePercent,
              expenses: state.financial.apOutstanding,
              avgTransaction: state.revenue.averageTransactionValue,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Revenue chart with period selector
          FadeScaleIn(
            delay: const Duration(milliseconds: 240),
            child: _ChartSection(
              chartData: state.chartData,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Inventory overview
          FadeScaleIn(
            delay: const Duration(milliseconds: 320),
            child: _InventorySection(
              inventory: state.inventory,
              isDark: isDark,
            ),
          ),

          // Financial overview
          const SizedBox(height: AppSpacing.lg),
          FadeScaleIn(
            delay: const Duration(milliseconds: 400),
            child: _FinancialSection(
              financial: state.financial,
              isDark: isDark,
            ),
          ),

          // Bottom padding for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

/// Partial error banner
class _PartialErrorBanner extends StatelessWidget {
  final List<String> errors;
  final bool isDark;
  final VoidCallback onRetry;

  const _PartialErrorBanner({
    required this.errors,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Could not load: ${errors.join(', ')}',
              style: AppTypography.caption1.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: AppTypography.caption1.copyWith(
                color: AppColors.royalBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero card showing current balance with gradient background.
class _BalanceHeroCard extends StatelessWidget {
  final double balance;
  final double changePercent;
  final double todayRevenue;
  final int transactionCount;
  final double weekRevenue;
  final int weekTransactions;

  const _BalanceHeroCard({
    required this.balance,
    required this.changePercent,
    required this.todayRevenue,
    required this.transactionCount,
    required this.weekRevenue,
    required this.weekTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.royalBlue, AppColors.royalBlueLight],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.currentBalance,
            style: AppTypography.subheadline.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.currency(balance),
            style: AppTypography.largeTitle.copyWith(
              color: AppColors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (changePercent >= 0 ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      changePercent >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      Formatters.percentage(changePercent),
                      style: AppTypography.caption1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'this month',
                style: AppTypography.caption1.copyWith(color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                _HeroMiniStat(
                  label: 'Today',
                  value: Formatters.compactCurrency(todayRevenue),
                  sub: '${Formatters.integer(transactionCount)} txn',
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _HeroMiniStat(
                  label: 'This Week',
                  value: Formatters.compactCurrency(weekRevenue),
                  sub: '${Formatters.integer(weekTransactions)} txn',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  const _HeroMiniStat({required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headline.copyWith(
              color: AppColors.white,
              fontSize: 15,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 1),
            Text(
              sub!,
              style: AppTypography.caption2.copyWith(color: Colors.white54),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption2.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

/// Revenue and expenses side-by-side summary cards.
class _SummaryPillRow extends StatelessWidget {
  final double revenue;
  final double revenueChange;
  final double expenses;
  final double avgTransaction;
  final bool isDark;

  const _SummaryPillRow({
    required this.revenue,
    required this.revenueChange,
    required this.expenses,
    required this.avgTransaction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryPill(
            label: AppStrings.revenue,
            value: Formatters.compactCurrency(revenue),
            change: revenueChange,
            color: AppColors.income,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryPill(
            label: 'Avg. Transaction',
            value: Formatters.compactCurrency(avgTransaction),
            color: AppColors.royalBlue,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final double? change;
  final Color color;
  final bool isDark;

  const _SummaryPill({
    required this.label,
    required this.value,
    this.change,
    required this.color,
    required this.isDark,
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
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
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
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.footnote.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.headline),
          if (change != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  change! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: change! >= 0 ? AppColors.income : AppColors.expense,
                ),
                const SizedBox(width: 2),
                Text(
                  '${Formatters.percentage(change!)} this month',
                  style: AppTypography.caption1.copyWith(
                    color: change! >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Revenue chart with period selector
class _ChartSection extends StatelessWidget {
  final List<RevenueChartData> chartData;
  final bool isDark;

  const _ChartSection({required this.chartData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final selectedPeriod = cubit.chartPeriod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Revenue Trend',
                style: AppTypography.title3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            _PeriodChip(
              label: 'Day',
              selected: selectedPeriod == 'daily',
              onTap: () => cubit.changeChartPeriod('daily'),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _PeriodChip(
              label: 'Week',
              selected: selectedPeriod == 'weekly',
              onTap: () => cubit.changeChartPeriod('weekly'),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _PeriodChip(
              label: 'Month',
              selected: selectedPeriod == 'monthly',
              onTap: () => cubit.changeChartPeriod('monthly'),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (chartData.isEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Center(
              child: Text(
                'No chart data available',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          )
        else
          RevenueLineChart(data: chartData),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.royalBlue
              : (isDark ? AppColors.darkFill : AppColors.fill),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTypography.caption1.copyWith(
            color: selected
                ? Colors.white
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Inventory overview section with metric cards.
class _InventorySection extends StatelessWidget {
  final InventorySummary inventory;
  final bool isDark;

  const _InventorySection({
    required this.inventory,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.inventoryOverview,
          style: AppTypography.title3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                value: Formatters.integer(inventory.activeSkuCount),
                label: 'Active SKUs',
                icon: Icons.inventory_2_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                value: Formatters.integer(inventory.lowStockCount),
                label: 'Low Stock',
                icon: Icons.warning_amber_outlined,
                color: inventory.lowStockCount > 0 ? AppColors.warning : null,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                value: Formatters.integer(inventory.outOfStockCount),
                label: 'Out of Stock',
                icon: Icons.remove_shopping_cart_outlined,
                color: inventory.outOfStockCount > 0 ? AppColors.error : null,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                value: Formatters.compactCurrency(
                    inventory.totalInventoryValue),
                label: 'Total Value',
                icon: Icons.account_balance_wallet_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                value: Formatters.integer(inventory.expiringCount),
                label: 'Expiring Soon',
                icon: Icons.schedule_outlined,
                color: inventory.expiringCount > 0
                    ? AppColors.warning
                    : null,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                value: Formatters.integer(inventory.totalSkuCount),
                label: 'Total SKUs',
                icon: Icons.category_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Financial overview section.
class _FinancialSection extends StatelessWidget {
  final FinancialSummary financial;
  final bool isDark;

  const _FinancialSection({
    required this.financial,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Overview',
          style: AppTypography.title3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Net position highlight
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: financial.netCashPosition >= 0
                ? AppColors.income.withValues(alpha: 0.08)
                : AppColors.expense.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: financial.netCashPosition >= 0
                  ? AppColors.income.withValues(alpha: 0.2)
                  : AppColors.expense.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                financial.netCashPosition >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: financial.netCashPosition >= 0
                    ? AppColors.income
                    : AppColors.expense,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Net Cash Position',
                  style: AppTypography.subheadline.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                Formatters.currency(financial.netCashPosition),
                style: AppTypography.headline.copyWith(
                  color: financial.netCashPosition >= 0
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
            children: [
              _FinancialRow(
                label: 'Bank Balance',
                value: Formatters.currency(financial.totalBankBalance),
                icon: Icons.account_balance_outlined,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _FinancialRow(
                label: 'Cash Balance',
                value: Formatters.currency(financial.totalCashBalance),
                icon: Icons.payments_outlined,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _FinancialRow(
                label: 'Receivable (AR)',
                value: Formatters.currency(financial.arOutstanding),
                icon: Icons.call_received_outlined,
                color: AppColors.income,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _FinancialRow(
                label: 'Payable (AP)',
                value: Formatters.currency(financial.apOutstanding),
                icon: Icons.call_made_outlined,
                color: AppColors.expense,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkSeparator : AppColors.separator,
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final bool isDark;

  const _FinancialRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ??
                (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.subheadline.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.subheadline.copyWith(
              fontWeight: FontWeight.w600,
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

/// Individual metric card for inventory and stats.
class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? color;
  final bool isDark;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
    required this.isDark,
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
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: color ??
                (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headline.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption2.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
