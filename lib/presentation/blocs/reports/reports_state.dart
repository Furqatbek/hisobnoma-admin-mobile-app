part of 'reports_cubit.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsLoaded extends ReportsState {
  final List<RevenueChartData> chartData;
  final RevenueSummary revenueSummary;
  final String selectedPeriod;
  final InventorySummary? inventory;
  final FinancialSummary? financial;

  const ReportsLoaded({
    required this.chartData,
    required this.revenueSummary,
    required this.selectedPeriod,
    this.inventory,
    this.financial,
  });

  @override
  List<Object?> get props => [
    chartData,
    revenueSummary,
    selectedPeriod,
    inventory,
    financial,
  ];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError({required this.message});

  @override
  List<Object?> get props => [message];
}
