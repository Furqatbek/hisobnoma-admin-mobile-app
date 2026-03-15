import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Attaches JWT Bearer token to all requests and handles token refresh on 401.
/// Uses a request queue to prevent multiple simultaneous refresh attempts.
class AuthInterceptor extends QueuedInterceptor {
  final FlutterSecureStorage _secureStorage;
  final Future<void> Function()? onTokenExpired;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _permissionsKey = 'permissions';

  bool _isRefreshing = false;

  AuthInterceptor({
    required FlutterSecureStorage secureStorage,
    this.onTokenExpired,
  }) : _secureStorage = secureStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login/refresh endpoints
    final isAuthEndpoint = options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh');

    if (!isAuthEndpoint) {
      final token = await _secureStorage.read(key: _accessTokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip refresh for auth endpoints themselves
    final isAuthEndpoint = err.requestOptions.path.contains('/auth/login') ||
        err.requestOptions.path.contains('/auth/refresh');
    if (isAuthEndpoint) {
      return handler.next(err);
    }

    // Attempt token refresh (QueuedInterceptor serializes these)
    if (!_isRefreshing) {
      _isRefreshing = true;
      final refreshed = await _tryRefreshToken(err.requestOptions);
      _isRefreshing = false;

      if (refreshed) {
        // Retry the original request with new token
        final token = await _secureStorage.read(key: _accessTokenKey);
        err.requestOptions.headers['Authorization'] = 'Bearer $token';

        try {
          final dio = Dio(BaseOptions(
            baseUrl: err.requestOptions.baseUrl,
            headers: err.requestOptions.headers,
          ));
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (retryError) {
          // Retry also failed
          if (retryError is DioException) {
            return handler.next(retryError);
          }
        }
      }

      // Token refresh failed — notify app to handle logout
      await clearTokens();
      onTokenExpired?.call();
    }

    handler.next(err);
  }

  Future<bool> _tryRefreshToken(RequestOptions originalRequest) async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final dio = Dio(BaseOptions(
        baseUrl: originalRequest.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        await saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {
      // Refresh failed
    }
    return false;
  }

  // === Public Token Management ===

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveUserInfo({
    required int userId,
    required List<String> permissions,
  }) async {
    await _secureStorage.write(key: _userIdKey, value: userId.toString());
    await _secureStorage.write(
      key: _permissionsKey,
      value: permissions.join(','),
    );
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _permissionsKey);
  }

  Future<String?> getAccessToken() {
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null;
  }

  Future<int?> getUserId() async {
    final id = await _secureStorage.read(key: _userIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  Future<List<String>> getPermissions() async {
    final perms = await _secureStorage.read(key: _permissionsKey);
    if (perms == null || perms.isEmpty) return [];
    return perms.split(',');
  }

  /// Check if user has a specific RBAC permission
  Future<bool> hasPermission(String permission) async {
    final perms = await getPermissions();
    return perms.contains(permission);
  }
}
