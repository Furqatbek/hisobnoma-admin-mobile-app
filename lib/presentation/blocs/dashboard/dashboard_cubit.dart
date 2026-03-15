import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/models/dashboard/dashboard_models.dart';
import 'package:hisobnoma/data/repositories/dashboard_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardCubit({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());
    await _fetchData();
  }

  Future<void> refresh() async => _fetchData();

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _dashboardRepository.getRevenueSummary(),
        _dashboardRepository.getInventorySummary(),
        _dashboardRepository.getFinancialSummary(),
        _dashboardRepository.getRevenueChart(),
      ]);

      emit(DashboardLoaded(
        revenue: results[0] as RevenueSummary,
        inventory: results[1] as InventorySummary,
        financial: results[2] as FinancialSummary,
        chartData: results[3] as List<RevenueChartData>,
      ));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}
