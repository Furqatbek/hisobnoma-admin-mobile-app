import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Attaches JWT Bearer token to all requests and handles token refresh on 401
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Future<void> Function()? onTokenExpired;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

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
    if (err.response?.statusCode == 401) {
      // Try to refresh the token
      final refreshed = await _tryRefreshToken(err.requestOptions);
      if (refreshed) {
        // Retry the original request with new token
        final token = await _secureStorage.read(key: _accessTokenKey);
        err.requestOptions.headers['Authorization'] = 'Bearer $token';

        try {
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // Refresh failed, force logout
        }
      }

      // Token refresh failed — notify app to handle logout
      onTokenExpired?.call();
    }

    handler.next(err);
  }

  Future<bool> _tryRefreshToken(RequestOptions originalRequest) async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final dio = Dio(BaseOptions(baseUrl: originalRequest.baseUrl));
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await _secureStorage.write(
          key: _accessTokenKey,
          value: data['accessToken'],
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: data['refreshToken'],
        );
        return true;
      }
    } catch (_) {
      // Refresh failed
    }
    return false;
  }

  // Public methods for token management
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null;
  }
}
