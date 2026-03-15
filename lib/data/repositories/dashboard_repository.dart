import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';

/// Repository for dashboard data
class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get revenue summary
  Future<Map<String, dynamic>> getRevenueSummary() async {
    final response = await _apiClient.get(ApiEndpoints.revenueSummary);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get revenue chart data
  Future<List<Map<String, dynamic>>> getRevenueChart({
    String period = 'daily',
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.revenueChart,
      queryParameters: {'period': period},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return (data['dailyRevenue'] as List).cast<Map<String, dynamic>>();
  }

  /// Get inventory summary
  Future<Map<String, dynamic>> getInventorySummary() async {
    final response = await _apiClient.get(ApiEndpoints.inventorySummary);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get financial summary
  Future<Map<String, dynamic>> getFinancialSummary() async {
    final response = await _apiClient.get(ApiEndpoints.financialSummary);
    return response.data['data'] as Map<String, dynamic>;
  }
}
