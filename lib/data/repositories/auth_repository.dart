import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/core/network/interceptors/auth_interceptor.dart';
import 'package:hisobnoma/data/models/auth/auth_models.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _apiClient;
  final AuthInterceptor _authInterceptor;

  AuthRepository({
    required ApiClient apiClient,
    required AuthInterceptor authInterceptor,
  }) : _apiClient = apiClient,
       _authInterceptor = authInterceptor;

  /// Fetch list of user accounts
  Future<List<UserAccount>> getUsers() async {
    final response = await _apiClient.get(ApiEndpoints.usersList);
    return (response.data['data'] as List)
        .map((e) => UserAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Login with username + PIN
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final loginResponse = LoginResponse.fromJson(data);

    await _authInterceptor.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );
    await _authInterceptor.saveUserInfo(
      userId: loginResponse.userId,
      permissions: loginResponse.permissions,
    );

    return loginResponse;
  }

  /// Register device for push notifications
  Future<DeviceInfo> registerDevice(DeviceRegistration registration) async {
    final response = await _apiClient.post(
      ApiEndpoints.registerDevice,
      data: registration.toJson(),
    );
    return DeviceInfo.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get registered devices
  Future<List<DeviceInfo>> getDevices() async {
    final response = await _apiClient.get(ApiEndpoints.devices);
    return (response.data['data'] as List)
        .map((e) => DeviceInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deactivate a device
  Future<void> deactivateDevice(String deviceId) async {
    await _apiClient.delete(ApiEndpoints.deactivateDevice(deviceId));
  }

  /// Logout and optionally deactivate device
  Future<void> logout({String? deviceId}) async {
    try {
      await _apiClient.post(
        ApiEndpoints.logout,
        queryParameters: deviceId != null ? {'deviceId': deviceId} : null,
      );
    } catch (_) {
      // Proceed with local cleanup even if API call fails
    }
    await _authInterceptor.clearTokens();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() => _authInterceptor.hasToken();

  /// Get current user's permissions
  Future<List<String>> getPermissions() => _authInterceptor.getPermissions();
}
