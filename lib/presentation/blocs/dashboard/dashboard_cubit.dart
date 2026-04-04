import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/models/dashboard/dashboard_models.dart';
import 'package:hisobnoma/data/repositories/dashboard_repository.dart';
import 'package:intl/intl.dart';

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

  Future<void> refresh() async {
    final prev = state;
    await _fetchData(previous: prev is DashboardLoaded ? prev : null);
  }

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

  Future<void> _fetchData({DashboardLoaded? previous}) async {
    RevenueSummary? revenue;
    InventorySummary? inventory;
    FinancialSummary? financial;
    List<RevenueChartData>? chartData;
    String? usdRate;
    String? usdDiff;
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
      _fetchUsdRate().then((v) {
        usdRate = v?.$1;
        usdDiff = v?.$2;
      }),
    ]);

    // If all failed and no previous data, show error
    if (revenue == null && inventory == null && financial == null) {
      if (previous == null) {
        emit(DashboardError(
          message: 'Unable to load dashboard data. Check your connection.',
        ));
        return;
      }
      // On refresh failure, keep previous data with error banner
      emit(DashboardLoaded(
        revenue: previous.revenue,
        inventory: previous.inventory,
        financial: previous.financial,
        chartData: previous.chartData,
        lastUpdated: previous.lastUpdated,
        partialErrors: errors,
        usdRate: previous.usdRate,
        usdDiff: previous.usdDiff,
      ));
      return;
    }

    // On refresh, fall back to previous data for any failed section
    emit(DashboardLoaded(
      revenue: revenue ?? previous?.revenue ?? _emptyRevenue,
      inventory: inventory ?? previous?.inventory ?? _emptyInventory,
      financial: financial ?? previous?.financial ?? _emptyFinancial,
      chartData: chartData ?? previous?.chartData ?? [],
      lastUpdated: DateTime.now(),
      partialErrors: errors.isEmpty ? null : errors,
      usdRate: usdRate ?? previous?.usdRate,
      usdDiff: usdDiff ?? previous?.usdDiff,
    ));
  }

  Future<(String, String)?> _fetchUsdRate() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dio = Dio();
      final response = await dio.get<List<dynamic>>(
        'https://cbu.uz/uz/arkhiv-kursov-valyut/json/usd/$today',
      );
      final data = response.data;
      if (data != null && data.isNotEmpty) {
        final item = data[0] as Map<String, dynamic>;
        return (item['Rate'] as String, item['Diff'] as String);
      }
    } catch (_) {
      // Currency rate is non-critical, silently ignore
    }
    return null;
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
