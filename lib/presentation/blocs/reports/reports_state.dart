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

  const ReportsLoaded({
    required this.chartData,
    required this.revenueSummary,
    required this.selectedPeriod,
  });

  @override
  List<Object?> get props => [chartData, revenueSummary, selectedPeriod];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError({required this.message});

  @override
  List<Object?> get props => [message];
}
