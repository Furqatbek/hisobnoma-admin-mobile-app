import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/data/models/dashboard/dashboard_models.dart';

/// Repository for dashboard data
class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get revenue summary
  Future<RevenueSummary> getRevenueSummary() async {
    final response = await _apiClient.get(ApiEndpoints.revenueSummary);
    return RevenueSummary.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Get revenue chart data
  Future<List<RevenueChartData>> getRevenueChart({
    String period = 'daily',
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.revenueChart,
      queryParameters: {'period': period},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return (data['dailyRevenue'] as List)
        .map((e) => RevenueChartData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get inventory summary
  Future<InventorySummary> getInventorySummary() async {
    final response = await _apiClient.get(ApiEndpoints.inventorySummary);
    return InventorySummary.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Get financial summary
  Future<FinancialSummary> getFinancialSummary() async {
    final response = await _apiClient.get(ApiEndpoints.financialSummary);
    return FinancialSummary.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
