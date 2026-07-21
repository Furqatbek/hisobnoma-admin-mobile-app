part of 'dashboard_cubit.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final RevenueSummary revenue;
  final InventorySummary inventory;
  final FinancialSummary financial;
  final List<RevenueChartData> chartData;
  final DateTime? lastUpdated;
  final List<String>? partialErrors;
  final String? usdRate;
  final String? usdDiff;

  const DashboardLoaded({
    required this.revenue,
    required this.inventory,
    required this.financial,
    required this.chartData,
    this.lastUpdated,
    this.partialErrors,
    this.usdRate,
    this.usdDiff,
  });

  DashboardLoaded copyWith({
    RevenueSummary? revenue,
    InventorySummary? inventory,
    FinancialSummary? financial,
    List<RevenueChartData>? chartData,
    DateTime? lastUpdated,
    List<String>? partialErrors,
    String? usdRate,
    String? usdDiff,
  }) {
    return DashboardLoaded(
      revenue: revenue ?? this.revenue,
      inventory: inventory ?? this.inventory,
      financial: financial ?? this.financial,
      chartData: chartData ?? this.chartData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      partialErrors: partialErrors ?? this.partialErrors,
      usdRate: usdRate ?? this.usdRate,
      usdDiff: usdDiff ?? this.usdDiff,
    );
  }

  @override
  List<Object?> get props => [
    revenue,
    inventory,
    financial,
    chartData,
    lastUpdated,
    partialErrors,
    usdRate,
    usdDiff,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
