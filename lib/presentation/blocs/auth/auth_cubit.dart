import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/models/auth/auth_models.dart';
import 'package:hisobnoma/data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial());

  Future<void> checkAuth() async {
    final isAuth = await _authRepository.isAuthenticated();
    if (isAuth) {
      final permissions = await _authRepository.getPermissions();
      emit(AuthAuthenticated(permissions: permissions));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Login with username + pin
  Future<void> login({
    required String username,
    required String pin,
  }) async {
    emit(const AuthLoading());
    try {
      final response = await _authRepository.login(
        LoginRequest(username: username, pin: pin),
      );
      emit(AuthAuthenticated(
        userId: response.userId,
        permissions: response.permissions,
      ));
    } catch (e) {
      emit(AuthError(message: _parseError(e)));
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
    } catch (_) {
      // Proceed with logout even on failure
    }
    emit(const AuthUnauthenticated());
  }

  String _parseError(Object error) {
    final message = error.toString();
    if (message.contains('UNAUTHORIZED') ||
        message.contains('Invalid or expired')) {
      return 'Invalid username or PIN. Please try again.';
    }
    if (message.contains('NETWORK_ERROR') ||
        message.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }
    if (message.contains('RATE_LIMITED')) {
      return 'Too many attempts. Please wait a moment.';
    }
    return 'Something went wrong. Please try again.';
  }
}
