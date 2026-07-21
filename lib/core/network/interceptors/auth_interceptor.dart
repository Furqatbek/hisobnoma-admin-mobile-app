import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hisobnoma/core/network/tls_policy.dart';

/// Outcome of a token-refresh attempt.
enum _RefreshOutcome {
  /// New tokens obtained.
  success,

  /// Server actively rejected the refresh (bad/expired refresh token).
  /// The session is truly over — tokens should be cleared and the user
  /// routed to login.
  rejected,

  /// Could not reach the server (timeout / connection error). The refresh
  /// token may still be valid — DO NOT clear it; just fail this request so
  /// the user can retry when connectivity returns.
  networkError,
}

/// Attaches JWT Bearer token to all requests and handles token refresh on 401.
/// Uses a request queue to prevent multiple simultaneous refresh attempts.
class AuthInterceptor extends QueuedInterceptor {
  final FlutterSecureStorage _secureStorage;

  /// Invoked when the session has truly expired (refresh rejected by the
  /// server). Wired after app start to route the user to login. Settable
  /// because the interceptor is constructed before the AuthCubit exists.
  Future<void> Function()? onTokenExpired;

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
    final isAuthEndpoint =
        options.path.contains('/auth/pin-login') ||
        options.path.contains('/auth/users/list') ||
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
    final isAuthEndpoint =
        err.requestOptions.path.contains('/auth/pin-login') ||
        err.requestOptions.path.contains('/auth/refresh');
    if (isAuthEndpoint) {
      return handler.next(err);
    }

    // Attempt token refresh (QueuedInterceptor serializes these)
    if (!_isRefreshing) {
      _isRefreshing = true;
      final outcome = await _tryRefreshToken(err.requestOptions);
      _isRefreshing = false;

      if (outcome == _RefreshOutcome.success) {
        // Retry the original request with new token
        final token = await _secureStorage.read(key: _accessTokenKey);
        err.requestOptions.headers['Authorization'] = 'Bearer $token';

        try {
          final dio = Dio(
            BaseOptions(
              baseUrl: err.requestOptions.baseUrl,
              headers: err.requestOptions.headers,
            ),
          );
          applyTlsPolicy(dio, allowedHost: err.requestOptions.uri.host);
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (retryError) {
          // Retry also failed
          if (retryError is DioException) {
            return handler.next(retryError);
          }
        }
      } else if (outcome == _RefreshOutcome.rejected) {
        // The refresh token itself is bad/expired — the session is truly over.
        // Clear tokens and let the app route to login.
        await clearTokens();
        await onTokenExpired?.call();
      }
      // _RefreshOutcome.networkError: keep tokens intact; just fail this
      // request. A transient network blip must never destroy a valid session.
    }

    handler.next(err);
  }

  Future<_RefreshOutcome> _tryRefreshToken(
    RequestOptions originalRequest,
  ) async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    // No refresh token at all → the user must log in again.
    if (refreshToken == null) return _RefreshOutcome.rejected;

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: originalRequest.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      applyTlsPolicy(dio, allowedHost: originalRequest.uri.host);
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
        return _RefreshOutcome.success;
      }
      // 2xx but unexpected shape → treat as a rejection.
      return _RefreshOutcome.rejected;
    } on DioException catch (e) {
      // Could not reach the server — keep the (possibly still valid) tokens.
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return _RefreshOutcome.networkError;
      }
      // Server actively refused the refresh (401/403/400) → session over.
      return _RefreshOutcome.rejected;
    } catch (_) {
      // Unknown failure — do not nuke a potentially valid session.
      return _RefreshOutcome.networkError;
    }
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
