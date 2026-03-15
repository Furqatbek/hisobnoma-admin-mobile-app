import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/router/app_router.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/presentation/blocs/dashboard/dashboard_cubit.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName, style: AppTypography.headline),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.alerts),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const DashboardShimmer();
          }
          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: AppTypography.body),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<DashboardCubit>().loadDashboard(),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }
          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().refresh(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  _buildHeroCard(state, isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildSummaryRow(state, isDark),
                  const SizedBox(height: AppSpacing.lg),
                  Text(AppStrings.inventoryOverview,
                      style: AppTypography.title3),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInventoryRow(state, isDark),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open add transaction bottom sheet
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeroCard(DashboardLoaded state, bool isDark) {
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
            style: AppTypography.subheadline.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.currency(state.financial.netCashPosition),
            style: AppTypography.title1.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                state.revenue.monthChangePercent >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${Formatters.percentage(state.revenue.monthChangePercent)} this month',
                style: AppTypography.footnote.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(DashboardLoaded state, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: AppStrings.revenue,
            value: Formatters.compactCurrency(state.revenue.thisMonthRevenue),
            change: state.revenue.weekChangePercent,
            color: AppColors.income,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            label: AppStrings.expenses,
            value:
                Formatters.compactCurrency(state.financial.apOutstanding),
            change: -3.2,
            color: AppColors.expense,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required double change,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.footnote.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              )),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.percentage(change),
            style: AppTypography.caption1.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(DashboardLoaded state, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            value: Formatters.integer(state.inventory.activeSkuCount),
            label: 'Active',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildMetricCard(
            value: Formatters.integer(state.inventory.lowStockCount),
            label: 'Low Stock',
            color: AppColors.warning,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildMetricCard(
            value: Formatters.integer(state.inventory.outOfStockCount),
            label: 'Out',
            color: AppColors.error,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String value,
    required String label,
    Color? color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.title2.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
