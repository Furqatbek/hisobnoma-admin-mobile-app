import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/data/models/sync/sync_models.dart';

/// Repository for offline sync operations
class SyncRepository {
  final ApiClient _apiClient;

  SyncRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get products for sync
  Future<SyncResponse<SyncProduct>> syncProducts({DateTime? lastSyncAt}) async {
    final response = await _apiClient.get(
      ApiEndpoints.syncProducts,
      queryParameters: {
        if (lastSyncAt != null) 'lastSyncAt': lastSyncAt.toIso8601String(),
      },
    );
    return SyncResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      itemsKey: 'products',
      fromJsonT: SyncProduct.fromJson,
    );
  }

  /// Get customers for sync
  Future<SyncResponse<SyncCustomer>> syncCustomers({
    DateTime? lastSyncAt,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.syncCustomers,
      queryParameters: {
        if (lastSyncAt != null) 'lastSyncAt': lastSyncAt.toIso8601String(),
      },
    );
    return SyncResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      itemsKey: 'customers',
      fromJsonT: SyncCustomer.fromJson,
    );
  }

  /// Get categories for sync
  Future<SyncResponse<SyncCategory>> syncCategories() async {
    final response = await _apiClient.get(ApiEndpoints.syncCategories);
    return SyncResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      itemsKey: 'categories',
      fromJsonT: SyncCategory.fromJson,
    );
  }

  /// Check last updated timestamp
  Future<DateTime?> getLastUpdated() async {
    final response = await _apiClient.get(ApiEndpoints.syncLastUpdated);
    final isoString = response.data['data'] as String?;
    return isoString != null ? DateTime.tryParse(isoString) : null;
  }
}
