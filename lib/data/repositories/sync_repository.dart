import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';

/// Repository for offline sync operations
class SyncRepository {
  final ApiClient _apiClient;

  SyncRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get products for sync
  Future<Map<String, dynamic>> syncProducts({DateTime? lastSyncAt}) async {
    final response = await _apiClient.get(
      ApiEndpoints.syncProducts,
      queryParameters: {
        if (lastSyncAt != null) 'lastSyncAt': lastSyncAt.toIso8601String(),
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get customers for sync
  Future<Map<String, dynamic>> syncCustomers({DateTime? lastSyncAt}) async {
    final response = await _apiClient.get(
      ApiEndpoints.syncCustomers,
      queryParameters: {
        if (lastSyncAt != null) 'lastSyncAt': lastSyncAt.toIso8601String(),
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get categories for sync
  Future<Map<String, dynamic>> syncCategories() async {
    final response = await _apiClient.get(ApiEndpoints.syncCategories);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Check last updated timestamp
  Future<DateTime?> getLastUpdated() async {
    final response = await _apiClient.get(ApiEndpoints.syncLastUpdated);
    final isoString = response.data['data'] as String?;
    return isoString != null ? DateTime.tryParse(isoString) : null;
  }
}
