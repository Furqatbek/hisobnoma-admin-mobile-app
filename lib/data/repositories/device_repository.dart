import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';

/// Registers/removes this device's push token with the backend so the server
/// can send APNs (iOS) — and later FCM (Android) — notifications to it.
class DeviceRepository {
  final ApiClient _apiClient;

  DeviceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Register (or refresh) this device's push token for the logged-in user.
  ///
  /// [platform] is "ios" (or "android" later). [environment] is "sandbox" for
  /// debug builds and "production" for release/TestFlight/App Store — the
  /// backend must send to the matching APNs host.
  Future<void> registerPushToken({
    required String token,
    required String platform,
    required String environment,
    String? appVersion,
  }) async {
    await _apiClient.post(
      ApiEndpoints.pushToken,
      data: {
        'token': token,
        'platform': platform,
        'environment': environment,
        if (appVersion != null) 'appVersion': appVersion,
      },
    );
  }

  /// Remove this device's push token (called on logout) so a logged-out phone
  /// stops receiving that user's notifications.
  Future<void> removePushToken({required String token}) async {
    await _apiClient.delete(ApiEndpoints.pushToken, data: {'token': token});
  }
}
