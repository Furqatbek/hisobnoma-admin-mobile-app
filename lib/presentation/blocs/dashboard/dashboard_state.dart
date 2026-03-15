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

  const DashboardLoaded({
    required this.revenue,
    required this.inventory,
    required this.financial,
    required this.chartData,
  });

  @override
  List<Object?> get props => [revenue, inventory, financial, chartData];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
