import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/repositories/dashboard_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardCubit({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());
    try {
      final results = await Future.wait([
        _dashboardRepository.getRevenueSummary(),
        _dashboardRepository.getInventorySummary(),
        _dashboardRepository.getFinancialSummary(),
        _dashboardRepository.getRevenueChart(),
      ]);

      emit(DashboardLoaded(
        revenue: results[0] as Map<String, dynamic>,
        inventory: results[1] as Map<String, dynamic>,
        financial: results[2] as Map<String, dynamic>,
        chartData: results[3] as List<Map<String, dynamic>>,
      ));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        _dashboardRepository.getRevenueSummary(),
        _dashboardRepository.getInventorySummary(),
        _dashboardRepository.getFinancialSummary(),
        _dashboardRepository.getRevenueChart(),
      ]);

      emit(DashboardLoaded(
        revenue: results[0] as Map<String, dynamic>,
        inventory: results[1] as Map<String, dynamic>,
        financial: results[2] as Map<String, dynamic>,
        chartData: results[3] as List<Map<String, dynamic>>,
      ));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}
