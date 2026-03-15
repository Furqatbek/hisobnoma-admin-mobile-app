import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/models/dashboard/dashboard_models.dart';
import 'package:hisobnoma/data/repositories/dashboard_repository.dart';

part 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final DashboardRepository _dashboardRepository;

  ReportsCubit({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(const ReportsInitial());

  Future<void> loadReports({String period = 'daily'}) async {
    emit(const ReportsLoading());
    try {
      final results = await Future.wait([
        _dashboardRepository.getRevenueChart(period: period),
        _dashboardRepository.getRevenueSummary(),
      ]);

      emit(ReportsLoaded(
        chartData: results[0] as List<RevenueChartData>,
        revenueSummary: results[1] as RevenueSummary,
        selectedPeriod: period,
      ));
    } catch (e) {
      emit(ReportsError(message: e.toString()));
    }
  }

  void changePeriod(String period) {
    loadReports(period: period);
  }
}
