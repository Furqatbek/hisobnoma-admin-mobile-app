import 'dart:math' as math;

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
    final maxY = data.map((d) => d.value).reduce(math.max);
    final minY = data.map((d) => d.value).reduce(math.min);
    final yRange = maxY - minY;

    // Handle flat data (all zeros or single value)
    final double chartMinY;
    final double chartMaxY;
    final double gridInterval;
    if (yRange == 0) {
      chartMinY = 0;
      chartMaxY = maxY > 0 ? maxY * 1.5 : 100;
      gridInterval = chartMaxY / 4;
    } else {
      chartMinY = (minY - yRange * 0.15).clamp(0.0, double.infinity);
      chartMaxY = maxY + yRange * 0.15;
      gridInterval = yRange / 4;
    }

    // Determine label skip interval based on item count
    final int labelInterval;
    if (data.length <= 7) {
      labelInterval = 1;
    } else if (data.length <= 14) {
      labelInterval = 2;
    } else {
      labelInterval = 3;
    }

    return Container(
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
            horizontalInterval: gridInterval,
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
                  if (index % labelInterval != 0) {
                    return const SizedBox.shrink();
                  }
                  // Shorten long labels (e.g. "MAY 2025" → "MAY")
                  final label = data[index].label;
                  final shortLabel = data.length > 7
                      ? label.split(' ').first
                      : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      shortLabel,
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 9,
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
                final index = spot.x.toInt();
                final label =
                    index >= 0 && index < data.length ? data[index].label : '';
                return LineTooltipItem(
                  '$label\n',
                  AppTypography.caption2.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: Formatters.compactCurrency(spot.y),
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.royalBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                show: data.length <= 14,
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
    );
  }
}
