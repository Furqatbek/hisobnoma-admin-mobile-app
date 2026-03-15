import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/dashboard/dashboard_models.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.reports, style: AppTypography.headline),
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
              'Unable to load reports',
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
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(ReportsLoaded state, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await context
            .read<ReportsCubit>()
            .loadReports(period: state.selectedPeriod);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Period selector
          FadeScaleIn(
            child: HisobSegmentedControl<String>(
              segments: const [
                HisobSegment(value: 'daily', label: 'Week'),
                HisobSegment(value: 'monthly', label: 'Month'),
                HisobSegment(value: 'yearly', label: 'Year'),
              ],
              selectedValue: state.selectedPeriod,
              onChanged: (period) {
                context.read<ReportsCubit>().changePeriod(period);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Revenue summary cards
          FadeScaleIn(
            delay: const Duration(milliseconds: 80),
            child: _RevenueSummaryCards(
              revenue: state.revenueSummary,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Revenue bar chart
          FadeScaleIn(
            delay: const Duration(milliseconds: 160),
            child: RevenueBarChart(
              data: state.chartData,
              title: AppStrings.revenueOverview,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Income vs Expense donut
          FadeScaleIn(
            delay: const Duration(milliseconds: 240),
            child: IncomeExpenseDonut(
              income: state.revenueSummary.thisMonthRevenue,
              expense: state.revenueSummary.lastMonthRevenue * 0.23,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Transaction stats
          FadeScaleIn(
            delay: const Duration(milliseconds: 320),
            child: _TransactionStats(
              revenue: state.revenueSummary,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Period comparison
          FadeScaleIn(
            delay: const Duration(milliseconds: 400),
            child: _PeriodComparison(
              revenue: state.revenueSummary,
              isDark: isDark,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
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
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Today',
            value: Formatters.compactCurrency(revenue.todayRevenue),
            change: revenue.todayChangePercent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: 'This Week',
            value: Formatters.compactCurrency(revenue.thisWeekRevenue),
            change: revenue.weekChangePercent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: 'This Month',
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

/// Transaction count stats section.
class _TransactionStats extends StatelessWidget {
  final RevenueSummary revenue;
  final bool isDark;

  const _TransactionStats({required this.revenue, required this.isDark});

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
          Text(
            'Transaction Stats',
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
                  label: 'Today',
                  value: Formatters.integer(revenue.todayTransactionCount),
                  icon: Icons.receipt_long_outlined,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'This Week',
                  value:
                      Formatters.integer(revenue.thisWeekTransactionCount),
                  icon: Icons.date_range_outlined,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'This Month',
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
                'Average Transaction',
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

/// Period-over-period comparison bars.
class _PeriodComparison extends StatelessWidget {
  final RevenueSummary revenue;
  final bool isDark;

  const _PeriodComparison({required this.revenue, required this.isDark});

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
          Text(
            'Period Comparison',
            style: AppTypography.headline.copyWith(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ComparisonRow(
            label: 'Today vs Yesterday',
            current: revenue.todayRevenue,
            previous: revenue.yesterdayRevenue,
            changePercent: revenue.todayChangePercent,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ComparisonRow(
            label: 'This Week vs Last',
            current: revenue.thisWeekRevenue,
            previous: revenue.lastWeekRevenue,
            changePercent: revenue.weekChangePercent,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ComparisonRow(
            label: 'This Month vs Last',
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
          SizedBox(height: AppSpacing.lg),
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
          LoadingShimmer(height: 240, borderRadius: AppSpacing.radiusCard),
        ],
      ),
    );
  }
}
