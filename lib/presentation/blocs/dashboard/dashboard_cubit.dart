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

  String _chartPeriod = 'daily';
  String get chartPeriod => _chartPeriod;

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());
    await _fetchData();
  }

  Future<void> refresh() async => _fetchData();

  Future<void> changeChartPeriod(String period) async {
    _chartPeriod = period;
    final currentState = state;
    if (currentState is DashboardLoaded) {
      try {
        final chartData =
            await _dashboardRepository.getRevenueChart(period: period);
        emit(currentState.copyWith(chartData: chartData));
      } catch (_) {
        // Keep current chart data on failure
      }
    }
  }

  Future<void> _fetchData() async {
    RevenueSummary? revenue;
    InventorySummary? inventory;
    FinancialSummary? financial;
    List<RevenueChartData>? chartData;
    final errors = <String>[];

    // Fetch all independently — don't let one failure block others
    await Future.wait([
      _dashboardRepository.getRevenueSummary().then((v) {
        revenue = v;
      }).catchError((Object e) {
        errors.add('Revenue');
      }),
      _dashboardRepository.getInventorySummary().then((v) {
        inventory = v;
      }).catchError((Object e) {
        errors.add('Inventory');
      }),
      _dashboardRepository.getFinancialSummary().then((v) {
        financial = v;
      }).catchError((Object e) {
        errors.add('Financial');
      }),
      _dashboardRepository.getRevenueChart(period: _chartPeriod).then((v) {
        chartData = v;
      }).catchError((Object e) {
        errors.add('Chart');
      }),
    ]);

    // If all failed, show error
    if (revenue == null && inventory == null && financial == null) {
      emit(DashboardError(
        message: 'Unable to load dashboard data. Check your connection.',
      ));
      return;
    }

    emit(DashboardLoaded(
      revenue: revenue ?? _emptyRevenue,
      inventory: inventory ?? _emptyInventory,
      financial: financial ?? _emptyFinancial,
      chartData: chartData ?? [],
      lastUpdated: DateTime.now(),
      partialErrors: errors.isEmpty ? null : errors,
    ));
  }

  static const _emptyRevenue = RevenueSummary(
    todayRevenue: 0, yesterdayRevenue: 0, thisWeekRevenue: 0,
    lastWeekRevenue: 0, thisMonthRevenue: 0, lastMonthRevenue: 0,
    todayChangePercent: 0, weekChangePercent: 0, monthChangePercent: 0,
    todayTransactionCount: 0, thisWeekTransactionCount: 0,
    thisMonthTransactionCount: 0, averageTransactionValue: 0,
  );

  static const _emptyInventory = InventorySummary(
    totalSkuCount: 0, activeSkuCount: 0, totalInventoryValue: 0,
    lowStockCount: 0, outOfStockCount: 0, expiringCount: 0,
  );

  static const _emptyFinancial = FinancialSummary(
    totalBankBalance: 0, totalCashBalance: 0, arOutstanding: 0,
    apOutstanding: 0, netCashPosition: 0,
  );
}
