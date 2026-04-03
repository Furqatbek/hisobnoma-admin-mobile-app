import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';

/// Donut chart showing income vs expense ratio with center label.
class IncomeExpenseDonut extends StatefulWidget {
  final double income;
  final double expense;

  const IncomeExpenseDonut({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  State<IncomeExpenseDonut> createState() => _IncomeExpenseDonutState();
}

class _IncomeExpenseDonutState extends State<IncomeExpenseDonut> {
  int _touchedIndex = -1;

  double get _total => widget.income + widget.expense;
  double get _incomePercent =>
      _total > 0 ? (widget.income / _total) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            S.of(context).incomeVsExpense,
            style: AppTypography.headline.copyWith(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Donut chart
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = response
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: _buildSections(),
                          startDegreeOffset: -90,
                        ),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                      ),
                      // Center label
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_incomePercent.toStringAsFixed(0)}%',
                            style: AppTypography.title2.copyWith(
                              color: AppColors.income,
                            ),
                          ),
                          Text(
                            S.of(context).income,
                            style: AppTypography.caption2.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(
                        color: AppColors.income,
                        label: S.of(context).income,
                        value: Formatters.compactCurrency(widget.income),
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LegendItem(
                        color: AppColors.expense,
                        label: S.of(context).expense,
                        value: Formatters.compactCurrency(widget.expense),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total = math.max(_total, 1.0);
    return [
      PieChartSectionData(
        value: widget.income,
        color: AppColors.income,
        radius: _touchedIndex == 0 ? 28 : 22,
        title: '',
        showTitle: false,
      ),
      PieChartSectionData(
        value: widget.expense > 0 ? widget.expense : total * 0.001,
        color: AppColors.expense,
        radius: _touchedIndex == 1 ? 28 : 22,
        title: '',
        showTitle: false,
      ),
    ];
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _LegendItem({
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
            shape: BoxShape.circle,
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
