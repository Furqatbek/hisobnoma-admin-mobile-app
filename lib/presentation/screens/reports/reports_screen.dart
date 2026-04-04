import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/dashboard/dashboard_models.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/reports/reports_cubit.dart';
import 'package:hisobnoma/presentation/widgets/charts/income_expense_donut.dart';
import 'package:hisobnoma/presentation/widgets/charts/revenue_bar_chart.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_segmented_control.dart';
import 'package:hisobnoma/presentation/widgets/common/loading_shimmer.dart';

/// Reports screen with charts, period selector, and breakdown summaries.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsCubit>().loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.reports, style: AppTypography.headline),
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) {
            return const _ReportsShimmer();
          }
          if (state is ReportsError) {
            return _buildError(state);
          }
          if (state is ReportsLoaded) {
            return _buildLoaded(state, isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(ReportsError state) {
    final t = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              t.unableToLoadReports,
              style: AppTypography.headline,
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
              onPressed: () => context.read<ReportsCubit>().loadReports(),
              child: Text(t.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(ReportsLoaded state, bool isDark) {
    final t = S.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await context
            .read<ReportsCubit>()
            .loadReports(period: state.selectedPeriod);
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          children: [
            const SizedBox(height: AppSpacing.sm),

            // Period selector
            FadeScaleIn(
              child: HisobSegmentedControl<String>(
                segments: [
                  HisobSegment(value: 'daily', label: t.week),
                  HisobSegment(value: 'monthly', label: t.month),
                  HisobSegment(value: 'yearly', label: t.year),
                ],
                selectedValue: state.selectedPeriod,
                onChanged: (period) {
                  context.read<ReportsCubit>().changePeriod(period);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Revenue hero card
            FadeScaleIn(
              delay: const Duration(milliseconds: 60),
              child: _RevenueHeroCard(
                revenue: state.revenueSummary,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Revenue summary cards
            FadeScaleIn(
              delay: const Duration(milliseconds: 120),
              child: _RevenueSummaryCards(
                revenue: state.revenueSummary,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Revenue bar chart
            FadeScaleIn(
              delay: const Duration(milliseconds: 180),
              child: RevenueBarChart(
                data: state.chartData,
                title: t.revenueOverview,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Income vs Expense donut
            FadeScaleIn(
              delay: const Duration(milliseconds: 240),
              child: IncomeExpenseDonut(
                income: state.revenueSummary.thisMonthRevenue,
                expense: state.financial?.apOutstanding ?? 0,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Cash flow section
            if (state.financial != null)
              FadeScaleIn(
                delay: const Duration(milliseconds: 300),
                child: _CashFlowSection(
                  financial: state.financial!,
                  isDark: isDark,
                ),
              ),
            if (state.financial != null)
              const SizedBox(height: AppSpacing.lg),

            // Transaction stats
            FadeScaleIn(
              delay: const Duration(milliseconds: 360),
              child: _TransactionStats(
                revenue: state.revenueSummary,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Inventory report
            if (state.inventory != null)
              FadeScaleIn(
                delay: const Duration(milliseconds: 420),
                child: _InventoryReport(
                  inventory: state.inventory!,
                  isDark: isDark,
                ),
              ),
            if (state.inventory != null)
              const SizedBox(height: AppSpacing.lg),

            // Period comparison
            FadeScaleIn(
              delay: const Duration(milliseconds: 480),
              child: _PeriodComparison(
                revenue: state.revenueSummary,
                isDark: isDark,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

/// Revenue hero card with monthly total and change indicator
class _RevenueHeroCard extends StatelessWidget {
  final RevenueSummary revenue;
  final bool isDark;

  const _RevenueHeroCard({required this.revenue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final isPositive = revenue.monthChangePercent >= 0;

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
            t.monthlyRevenue,
            style: AppTypography.subheadline.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.currency(revenue.thisMonthRevenue),
            style: AppTypography.largeTitle.copyWith(
              color: AppColors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.percentage(revenue.monthChangePercent),
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
                t.vsLastMonth,
                style:
                    AppTypography.caption1.copyWith(color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Mini stats row
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
                  value: Formatters.compactCurrency(revenue.todayRevenue),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _HeroMiniStat(
                  label: t.thisWeek,
                  value:
                      Formatters.compactCurrency(revenue.thisWeekRevenue),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _HeroMiniStat(
                  label: t.yesterday,
                  value: Formatters.compactCurrency(
                      revenue.yesterdayRevenue),
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

  const _HeroMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headline.copyWith(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
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

/// Top-level revenue summary cards row.
class _RevenueSummaryCards extends StatelessWidget {
  final RevenueSummary revenue;
  final bool isDark;

  const _RevenueSummaryCards({required this.revenue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: t.today,
            value: Formatters.compactCurrency(revenue.todayRevenue),
            change: revenue.todayChangePercent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: t.thisWeek,
            value: Formatters.compactCurrency(revenue.thisWeekRevenue),
            change: revenue.weekChangePercent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: t.thisMonthLabel,
            value: Formatters.compactCurrency(revenue.thisMonthRevenue),
            change: revenue.monthChangePercent,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final double change;
  final bool isDark;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.change,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
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
          Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headline.copyWith(
              fontSize: 15,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: isPositive ? AppColors.income : AppColors.expense,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  Formatters.percentage(change),
                  style: AppTypography.caption2.copyWith(
                    color: isPositive ? AppColors.income : AppColors.expense,
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

/// Cash flow section showing inflows vs outflows
class _CashFlowSection extends StatelessWidget {
  final FinancialSummary financial;
  final bool isDark;

  const _CashFlowSection({
    required this.financial,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final inflows = financial.totalBankBalance + financial.totalCashBalance;
    final outflows = financial.apOutstanding;
    final total = inflows + outflows;
    final inflowFraction = total > 0 ? inflows / total : 0.5;

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
          Text(
            t.cashFlow,
            style: AppTypography.headline.copyWith(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Flexible(
                    flex: (inflowFraction * 100).round().clamp(1, 99),
                    child: Container(color: AppColors.income),
                  ),
                  Flexible(
                    flex:
                        ((1 - inflowFraction) * 100).round().clamp(1, 99),
                    child: Container(color: AppColors.expense),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Legend row
          Row(
            children: [
              Expanded(
                child: _CashFlowItem(
                  color: AppColors.income,
                  label: t.inflows,
                  value: Formatters.compactCurrency(inflows),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _CashFlowItem(
                  color: AppColors.expense,
                  label: t.outflows,
                  value: Formatters.compactCurrency(outflows),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(
            color: isDark ? AppColors.darkSeparator : AppColors.separator,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.netCashPosition,
                style: AppTypography.subheadline.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
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
        ],
      ),
    );
  }
}

class _CashFlowItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _CashFlowItem({
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption1.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Transaction count stats section.
class _TransactionStats extends StatelessWidget {
  final RevenueSummary revenue;
  final bool isDark;

  const _TransactionStats({required this.revenue, required this.isDark});

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
          Text(
            t.transactionStats,
            style: AppTypography.headline.copyWith(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: t.today,
                  value: Formatters.integer(revenue.todayTransactionCount),
                  icon: Icons.receipt_long_outlined,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: t.thisWeek,
                  value:
                      Formatters.integer(revenue.thisWeekTransactionCount),
                  icon: Icons.date_range_outlined,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: t.thisMonthLabel,
                  value:
                      Formatters.integer(revenue.thisMonthTransactionCount),
                  icon: Icons.calendar_month_outlined,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            color: isDark ? AppColors.darkSeparator : AppColors.separator,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.averageTransaction,
                style: AppTypography.subheadline.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                Formatters.currency(revenue.averageTransactionValue),
                style: AppTypography.headline.copyWith(
                  color: AppColors.royalBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.title3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption2.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Inventory report section with stock health and value
class _InventoryReport extends StatelessWidget {
  final InventorySummary inventory;
  final bool isDark;

  const _InventoryReport({required this.inventory, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final total = inventory.totalSkuCount;
    final healthy =
        total - inventory.lowStockCount - inventory.outOfStockCount;
    final healthyPercent = total > 0 ? (healthy / total * 100) : 0.0;
    final lowPercent =
        total > 0 ? (inventory.lowStockCount / total * 100) : 0.0;
    final outPercent =
        total > 0 ? (inventory.outOfStockCount / total * 100) : 0.0;

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
          Text(
            t.inventoryReport,
            style: AppTypography.headline.copyWith(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Stock health bar
          Text(
            t.stockHealth,
            style: AppTypography.caption1.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (healthyPercent > 0)
                    Flexible(
                      flex: healthyPercent.round().clamp(1, 100),
                      child: Container(color: AppColors.income),
                    ),
                  if (lowPercent > 0)
                    Flexible(
                      flex: lowPercent.round().clamp(1, 100),
                      child: Container(color: AppColors.warning),
                    ),
                  if (outPercent > 0)
                    Flexible(
                      flex: outPercent.round().clamp(1, 100),
                      child: Container(color: AppColors.expense),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Legend
          Row(
            children: [
              _InventoryLegendItem(
                color: AppColors.income,
                label: t.healthy,
                value: '$healthy',
                isDark: isDark,
              ),
              const SizedBox(width: AppSpacing.md),
              _InventoryLegendItem(
                color: AppColors.warning,
                label: t.lowStock,
                value: '${inventory.lowStockCount}',
                isDark: isDark,
              ),
              const SizedBox(width: AppSpacing.md),
              _InventoryLegendItem(
                color: AppColors.expense,
                label: t.outOfStock,
                value: '${inventory.outOfStockCount}',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            color: isDark ? AppColors.darkSeparator : AppColors.separator,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.md),

          // Inventory metrics
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.inventoryValue,
                      style: AppTypography.caption1.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.compactCurrency(
                          inventory.totalInventoryValue),
                      style: AppTypography.headline.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.activeSkus,
                      style: AppTypography.caption1.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${inventory.activeSkuCount} / ${inventory.totalSkuCount}',
                      style: AppTypography.headline.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (inventory.expiringCount > 0)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.expiringSoon,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${inventory.expiringCount}',
                        style: AppTypography.headline.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _InventoryLegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$value $label',
              style: AppTypography.caption2.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Period-over-period comparison bars.
class _PeriodComparison extends StatelessWidget {
  final RevenueSummary revenue;
  final bool isDark;

  const _PeriodComparison({required this.revenue, required this.isDark});

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
          Text(
            t.periodComparison,
            style: AppTypography.headline.copyWith(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ComparisonRow(
            label: t.todayVsYesterday,
            current: revenue.todayRevenue,
            previous: revenue.yesterdayRevenue,
            changePercent: revenue.todayChangePercent,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ComparisonRow(
            label: t.thisWeekVsLast,
            current: revenue.thisWeekRevenue,
            previous: revenue.lastWeekRevenue,
            changePercent: revenue.weekChangePercent,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ComparisonRow(
            label: t.thisMonthVsLast,
            current: revenue.thisMonthRevenue,
            previous: revenue.lastMonthRevenue,
            changePercent: revenue.monthChangePercent,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double current;
  final double previous;
  final double changePercent;
  final bool isDark;

  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.changePercent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercent >= 0;
    // Calculate bar widths relative to the larger value
    final maxVal =
        current > previous ? current : (previous > 0 ? previous : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.caption1.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: isPositive ? AppColors.income : AppColors.expense,
                ),
                Text(
                  Formatters.percentage(changePercent),
                  style: AppTypography.caption1.copyWith(
                    color: isPositive ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Current bar
        _ProgressBar(
          label: Formatters.compactCurrency(current),
          fraction: maxVal > 0 ? current / maxVal : 0,
          color: AppColors.royalBlue,
          isDark: isDark,
        ),
        const SizedBox(height: 4),
        // Previous bar
        _ProgressBar(
          label: Formatters.compactCurrency(previous),
          fraction: maxVal > 0 ? previous / maxVal : 0,
          color: isDark
              ? AppColors.darkSeparator
              : AppColors.separator,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double fraction;
  final Color color;
  final bool isDark;

  const _ProgressBar({
    required this.label,
    required this.fraction,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Background
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkFill : AppColors.fill,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Fill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 8,
                    width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTypography.caption2.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// Shimmer loading for reports screen.
class _ReportsShimmer extends StatelessWidget {
  const _ReportsShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          LoadingShimmer(height: 36, borderRadius: AppSpacing.radiusSm),
          SizedBox(height: AppSpacing.md),
          LoadingShimmer(height: 160, borderRadius: AppSpacing.radiusLg),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: LoadingShimmer.card()),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: LoadingShimmer.card()),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: LoadingShimmer.card()),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          LoadingShimmer(height: 240, borderRadius: AppSpacing.radiusCard),
          SizedBox(height: AppSpacing.lg),
          LoadingShimmer(height: 180, borderRadius: AppSpacing.radiusCard),
        ],
      ),
    );
  }
}
