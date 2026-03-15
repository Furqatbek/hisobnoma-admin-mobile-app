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
        onPressed: () {
          // TODO: Open add transaction bottom sheet
        },
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
          // Greeting
          FadeScaleIn(
            child: Text(
              _greeting,
              style: AppTypography.title2.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Hero balance card
          FadeScaleIn(
            delay: const Duration(milliseconds: 80),
            child: _BalanceHeroCard(
              balance: state.financial.netCashPosition,
              changePercent: state.revenue.monthChangePercent,
              todayRevenue: state.revenue.todayRevenue,
              transactionCount: state.revenue.todayTransactionCount,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Revenue / Expenses summary pills
          FadeScaleIn(
            delay: const Duration(milliseconds: 160),
            child: _SummaryPillRow(
              revenue: state.revenue.thisMonthRevenue,
              revenueChange: state.revenue.weekChangePercent,
              expenses: state.financial.apOutstanding,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Revenue chart
          FadeScaleIn(
            delay: const Duration(milliseconds: 240),
            child: RevenueLineChart(data: state.chartData),
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

/// Hero card showing current balance with gradient background.
class _BalanceHeroCard extends StatelessWidget {
  final double balance;
  final double changePercent;
  final double todayRevenue;
  final int transactionCount;

  const _BalanceHeroCard({
    required this.balance,
    required this.changePercent,
    required this.todayRevenue,
    required this.transactionCount,
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
              Icon(
                changePercent >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${Formatters.percentage(changePercent)} this month',
                style: AppTypography.footnote.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Today's mini stats row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeroMiniStat(
                  label: 'Today',
                  value: Formatters.compactCurrency(todayRevenue),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white24,
                ),
                _HeroMiniStat(
                  label: 'Transactions',
                  value: Formatters.integer(transactionCount),
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
              fontSize: 15,
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

/// Revenue and expenses side-by-side summary cards.
class _SummaryPillRow extends StatelessWidget {
  final double revenue;
  final double revenueChange;
  final double expenses;
  final bool isDark;

  const _SummaryPillRow({
    required this.revenue,
    required this.revenueChange,
    required this.expenses,
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
            label: AppStrings.expenses,
            value: Formatters.compactCurrency(expenses),
            change: -3.2,
            color: AppColors.expense,
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
  final double change;
  final Color color;
  final bool isDark;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.change,
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
          Text(
            label,
            style: AppTypography.footnote.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.headline),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 2),
              Text(
                Formatters.percentage(change),
                style: AppTypography.caption1.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inventory overview section with 3 metric cards.
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
                color: AppColors.warning,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                value: Formatters.integer(inventory.outOfStockCount),
                label: 'Out of Stock',
                icon: Icons.remove_shopping_cart_outlined,
                color: AppColors.error,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Inventory value + expiring row
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
