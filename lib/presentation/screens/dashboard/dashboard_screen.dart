import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:hisobnoma/data/models/dashboard/dashboard_models.dart';
import 'package:hisobnoma/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:hisobnoma/presentation/widgets/charts/revenue_line_chart.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';
import 'package:hisobnoma/presentation/screens/transactions/add_sale_sheet.dart';
import 'package:hisobnoma/presentation/widgets/common/loading_shimmer.dart';
import 'package:hisobnoma/presentation/widgets/common/notification_bell.dart';

/// Main dashboard / home screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
    context.read<AlertsCubit>().loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName, style: AppTypography.headline),
        actions: const [
          NotificationBell(),
          SizedBox(width: AppSpacing.xs),
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

  Widget _buildErrorState(DashboardError state) {
    final t = S.of(context);
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
              t.unableToLoadDashboard,
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
              onPressed: () => context.read<DashboardCubit>().loadDashboard(),
              child: Text(t.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animate(Widget child, {Duration delay = Duration.zero}) {
    if (_hasAnimated) return child;
    return FadeScaleIn(delay: delay, child: child);
  }

  Widget _buildLoadedContent(DashboardLoaded state, bool isDark) {
    final content = RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await context.read<DashboardCubit>().refresh();
        if (mounted) {
          context.read<AlertsCubit>().loadUnreadCount();
        }
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          children: [
            const SizedBox(height: AppSpacing.sm),

            // USD/UZS rate + last updated
            if (state.usdRate != null)
              _animate(
                _CurrencyRateBanner(
                  rate: state.usdRate!,
                  diff: state.usdDiff,
                  lastUpdated: state.lastUpdated,
                  isDark: isDark,
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
            _animate(
              _BalanceHeroCard(
                balance: state.financial.netCashPosition,
                changePercent: state.revenue.monthChangePercent,
                todayRevenue: state.revenue.todayRevenue,
                transactionCount: state.revenue.todayTransactionCount,
                weekRevenue: state.revenue.thisWeekRevenue,
                weekTransactions: state.revenue.thisWeekTransactionCount,
              ),
              delay: const Duration(milliseconds: 80),
            ),
            const SizedBox(height: AppSpacing.md),

            // Revenue / Expenses summary pills
            _animate(
              _SummaryPillRow(
                revenue: state.revenue.thisMonthRevenue,
                revenueChange: state.revenue.monthChangePercent,
                expenses: state.financial.apOutstanding,
                avgTransaction: state.revenue.averageTransactionValue,
                isDark: isDark,
              ),
              delay: const Duration(milliseconds: 160),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Revenue chart with period selector
            _animate(
              _ChartSection(chartData: state.chartData, isDark: isDark),
              delay: const Duration(milliseconds: 240),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Inventory overview
            _animate(
              _InventorySection(inventory: state.inventory, isDark: isDark),
              delay: const Duration(milliseconds: 320),
            ),

            // Financial overview
            const SizedBox(height: AppSpacing.lg),
            _animate(
              _FinancialSection(financial: state.financial, isDark: isDark),
              delay: const Duration(milliseconds: 400),
            ),

            // Bottom padding for FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
    );

    if (!_hasAnimated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hasAnimated = true;
      });
    }
    return content;
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
    final t = S.of(context);
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
              t.couldNotLoad(errors.join(', ')),
              style: AppTypography.caption1.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              t.retry,
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

/// USD/UZS exchange rate banner
class _CurrencyRateBanner extends StatelessWidget {
  final String rate;
  final String? diff;
  final DateTime? lastUpdated;
  final bool isDark;

  const _CurrencyRateBanner({
    required this.rate,
    this.diff,
    this.lastUpdated,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final diffValue = double.tryParse(diff ?? '') ?? 0;
    final isPositive = diffValue >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
      child: Row(
        children: [
          Icon(Icons.attach_money, size: 20, color: AppColors.royalBlue),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'USD',
            style: AppTypography.subheadline.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$rate UZS',
            style: AppTypography.headline.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          if (diff != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.income : AppColors.expense)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: isPositive ? AppColors.income : AppColors.expense,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    diff!,
                    style: AppTypography.caption1.copyWith(
                      color: isPositive ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (lastUpdated != null)
            Text(
              Formatters.time(lastUpdated!),
              style: AppTypography.caption2.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textTertiary,
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
    final t = S.of(context);
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
            t.currentBalance,
            style: AppTypography.subheadline.copyWith(color: Colors.white70),
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
                  color:
                      (changePercent >= 0
                              ? AppColors.income
                              : AppColors.expense)
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
                t.thisMonth,
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
                  label: t.today,
                  value: Formatters.compactCurrency(todayRevenue),
                  sub: t.txnCount(Formatters.integer(transactionCount)),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _HeroMiniStat(
                  label: t.thisWeek,
                  value: Formatters.compactCurrency(weekRevenue),
                  sub: t.txnCount(Formatters.integer(weekTransactions)),
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
            style: AppTypography.caption2.copyWith(color: Colors.white60),
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
    final t = S.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryPill(
              label: t.revenue,
              value: Formatters.compactCurrency(revenue),
              change: revenueChange,
              color: AppColors.income,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryPill(
              label: t.avgTransaction,
              value: Formatters.compactCurrency(avgTransaction),
              color: AppColors.royalBlue,
              isDark: isDark,
            ),
          ),
        ],
      ),
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
    final t = S.of(context);
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          const Spacer(),
          if (change != null)
            Row(
              children: [
                Icon(
                  change! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: change! >= 0 ? AppColors.income : AppColors.expense,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${Formatters.percentage(change!)} ${t.thisMonth}',
                    style: AppTypography.caption1.copyWith(
                      color: change! >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
    final t = S.of(context);
    final cubit = context.read<DashboardCubit>();
    final selectedPeriod = cubit.chartPeriod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.revenueTrend,
                style: AppTypography.title3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            _PeriodChip(
              label: t.day,
              selected: selectedPeriod == 'daily',
              onTap: () => cubit.changeChartPeriod('daily'),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _PeriodChip(
              label: t.week,
              selected: selectedPeriod == 'weekly',
              onTap: () => cubit.changeChartPeriod('weekly'),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _PeriodChip(
              label: t.month,
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
                t.noChartData,
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

  const _InventorySection({required this.inventory, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.inventoryOverview,
          style: AppTypography.title3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  value: Formatters.integer(inventory.activeSkuCount),
                  label: t.activeSkus,
                  icon: Icons.inventory_2_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  value: Formatters.integer(inventory.lowStockCount),
                  label: t.lowStock,
                  icon: Icons.warning_amber_outlined,
                  color: inventory.lowStockCount > 0 ? AppColors.warning : null,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  value: Formatters.integer(inventory.outOfStockCount),
                  label: t.outOfStock,
                  icon: Icons.remove_shopping_cart_outlined,
                  color: inventory.outOfStockCount > 0 ? AppColors.error : null,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  value: Formatters.compactCurrency(
                    inventory.totalInventoryValue,
                  ),
                  label: t.totalValue,
                  icon: Icons.account_balance_wallet_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  value: Formatters.integer(inventory.expiringCount),
                  label: t.expiringSoon,
                  icon: Icons.schedule_outlined,
                  color: inventory.expiringCount > 0 ? AppColors.warning : null,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  value: Formatters.integer(inventory.totalSkuCount),
                  label: t.totalSkus,
                  icon: Icons.category_outlined,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Financial overview section.
class _FinancialSection extends StatelessWidget {
  final FinancialSummary financial;
  final bool isDark;

  const _FinancialSection({required this.financial, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.financialOverview,
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
                  t.netCashPosition,
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
                label: t.bankBalance,
                value: Formatters.currency(financial.totalBankBalance),
                icon: Icons.account_balance_outlined,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _FinancialRow(
                label: t.cashBalance,
                value: Formatters.currency(financial.totalCashBalance),
                icon: Icons.payments_outlined,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _FinancialRow(
                label: t.receivableAr,
                value: Formatters.currency(financial.arOutstanding),
                icon: Icons.call_received_outlined,
                color: AppColors.income,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _FinancialRow(
                label: t.payableAp,
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
            color:
                color ??
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
              color:
                  color ??
                  (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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
            color:
                color ??
                (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.headline.copyWith(color: color)),
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
