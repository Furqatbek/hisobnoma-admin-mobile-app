import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/core/network/interceptors/auth_interceptor.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _apiClient;
  final AuthInterceptor _authInterceptor;

  AuthRepository({
    required ApiClient apiClient,
    required AuthInterceptor authInterceptor,
  })  : _apiClient = apiClient,
        _authInterceptor = authInterceptor;

  /// Login with phone + OTP code
  Future<Map<String, dynamic>> login({
    required String phone,
    required String code,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'phone': phone, 'code': code},
    );
    final data = response.data['data'] as Map<String, dynamic>;

    await _authInterceptor.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    return data;
  }

  /// Refresh access token
  Future<void> refreshToken() async {
    // Handled by AuthInterceptor automatically
  }

  /// Register device for push notifications
  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String fcmToken,
    required String platform,
    required String deviceName,
    required String deviceModel,
    required String osVersion,
    required String appVersion,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.registerDevice,
      data: {
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': platform,
        'deviceName': deviceName,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'appVersion': appVersion,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get registered devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    final response = await _apiClient.get(ApiEndpoints.devices);
    return (response.data['data'] as List).cast<Map<String, dynamic>>();
  }

  /// Deactivate a device
  Future<void> deactivateDevice(String deviceId) async {
    await _apiClient.delete(ApiEndpoints.deactivateDevice(deviceId));
  }

  /// Logout and optionally deactivate device
  Future<void> logout({String? deviceId}) async {
    await _apiClient.post(
      ApiEndpoints.logout,
      queryParameters: deviceId != null ? {'deviceId': deviceId} : null,
    );
    await _authInterceptor.clearTokens();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() => _authInterceptor.hasToken();
}
