import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/dashboard/dashboard_models.dart';

/// Smooth curved revenue line chart for the dashboard.
class RevenueLineChart extends StatelessWidget {
  final List<RevenueChartData> data;

  const RevenueLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final minY = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final yRange = maxY - minY;
    final chartMinY = (minY - yRange * 0.15).clamp(0.0, double.infinity);
    final chartMaxY = maxY + yRange * 0.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Trend',
          style: AppTypography.title3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 200,
          padding: const EdgeInsets.only(
            right: AppSpacing.md,
            top: AppSpacing.sm,
          ),
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
          child: LineChart(
            LineChartData(
              minY: chartMinY,
              maxY: chartMaxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yRange > 0 ? yRange / 4 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark
                      ? AppColors.darkSeparator.withValues(alpha: 0.3)
                      : AppColors.separator.withValues(alpha: 0.5),
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.min || value == meta.max) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Text(
                          Formatters.compactCurrency(value, symbol: ''),
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      // Show every label if <=7 items, otherwise every other
                      if (data.length > 7 && index % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          data[index].label,
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => isDark
                      ? AppColors.darkElevated
                      : AppColors.cardBackground,
                  getTooltipItems: (spots) => spots.map((spot) {
                    return LineTooltipItem(
                      Formatters.compactCurrency(spot.y),
                      AppTypography.caption1.copyWith(
                        color: AppColors.royalBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                handleBuiltInTouches: true,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    data.length,
                    (i) => FlSpot(i.toDouble(), data[i].value),
                  ),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.royalBlue,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.royalBlue,
                      strokeWidth: 1.5,
                      strokeColor: isDark
                          ? AppColors.darkCard
                          : AppColors.cardBackground,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.royalBlue.withValues(alpha: 0.2),
                        AppColors.royalBlue.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }
}
