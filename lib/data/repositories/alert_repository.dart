import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';

/// Repository for alerts management
class AlertRepository {
  final ApiClient _apiClient;

  AlertRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get paginated alerts
  Future<Map<String, dynamic>> getAlerts({
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
    return response.data['data'] as Map<String, dynamic>;
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
  Future<List<Map<String, dynamic>>> getPreferences() async {
    final response = await _apiClient.get(ApiEndpoints.alertPreferences);
    return (response.data['data'] as List).cast<Map<String, dynamic>>();
  }

  /// Update alert preference
  Future<void> updatePreference({
    required String alertType,
    required bool pushEnabled,
    required bool inAppEnabled,
    required bool emailEnabled,
    required bool smsEnabled,
    int? thresholdValue,
  }) async {
    await _apiClient.put(
      ApiEndpoints.updateAlertPreference(alertType),
      data: {
        'pushEnabled': pushEnabled,
        'inAppEnabled': inAppEnabled,
        'emailEnabled': emailEnabled,
        'smsEnabled': smsEnabled,
        if (thresholdValue != null) 'thresholdValue': thresholdValue,
      },
    );
  }
}
