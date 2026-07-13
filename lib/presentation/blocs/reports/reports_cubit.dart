import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/utils/error_message.dart';
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
      List<RevenueChartData>? chartData;
      RevenueSummary? revenueSummary;
      InventorySummary? inventory;
      FinancialSummary? financial;

      await Future.wait([
        _dashboardRepository.getRevenueChart(period: period).then((v) {
          chartData = v;
        }).catchError((Object _) {}),
        _dashboardRepository.getRevenueSummary().then((v) {
          revenueSummary = v;
        }).catchError((Object _) {}),
        _dashboardRepository.getInventorySummary().then((v) {
          inventory = v;
        }).catchError((Object _) {}),
        _dashboardRepository.getFinancialSummary().then((v) {
          financial = v;
        }).catchError((Object _) {}),
      ]);

      if (revenueSummary == null) {
        emit(const ReportsError(message: 'Unable to load report data.'));
        return;
      }

      emit(ReportsLoaded(
        chartData: chartData ?? [],
        revenueSummary: revenueSummary!,
        selectedPeriod: period,
        inventory: inventory,
        financial: financial,
      ));
    } catch (e) {
      emit(ReportsError(message: extractErrorMessage(e)));
    }
  }

  void changePeriod(String period) {
    loadReports(period: period);
  }
}
