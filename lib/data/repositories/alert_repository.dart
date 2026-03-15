import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/core/network/api_response.dart';
import 'package:hisobnoma/data/models/alert/alert_models.dart';

/// Repository for alerts management
class AlertRepository {
  final ApiClient _apiClient;

  AlertRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get paginated alerts
  Future<PaginatedResponse<Alert>> getAlerts({
    bool? unreadOnly,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.alerts,
      queryParameters: {
        if (unreadOnly != null) 'unreadOnly': unreadOnly,
        'page': page,
        'size': size,
      },
    );
    return PaginatedResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      Alert.fromJson,
    );
  }

  /// Get unread alert count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.unreadCount);
    return response.data['data'] as int;
  }

  /// Mark single alert as read
  Future<void> markAsRead(int alertId) async {
    await _apiClient.put(ApiEndpoints.markRead(alertId));
  }

  /// Mark all alerts as read
  Future<void> markAllAsRead() async {
    await _apiClient.put(ApiEndpoints.markAllRead);
  }

  /// Get alert preferences
  Future<List<AlertPreference>> getPreferences() async {
    final response = await _apiClient.get(ApiEndpoints.alertPreferences);
    return (response.data['data'] as List)
        .map((e) => AlertPreference.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Update alert preference
  Future<void> updatePreference({
    required String alertType,
    required AlertPreference preference,
  }) async {
    await _apiClient.put(
      ApiEndpoints.updateAlertPreference(alertType),
      data: preference.toJson(),
    );
  }
}
