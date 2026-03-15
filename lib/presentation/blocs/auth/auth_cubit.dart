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

  /// Step 1: User submits phone number → show OTP screen
  void sendCode(String phone) {
    // In a real app, this would call an API to send SMS.
    // For now, we transition to the code-entry state.
    emit(AuthCodeSent(phone: phone));
  }

  /// Step 2: User enters OTP code → authenticate
  Future<void> verifyCode({
    required String phone,
    required String code,
  }) async {
    emit(const AuthLoading());
    try {
      final response = await _authRepository.login(
        LoginRequest(phone: phone, code: code),
      );
      emit(AuthAuthenticated(
        userId: response.userId,
        permissions: response.permissions,
      ));
    } catch (e) {
      emit(AuthError(
        message: _parseError(e),
        phone: phone,
      ));
    }
  }

  /// Go back to phone input from OTP screen
  void backToPhone() {
    emit(const AuthUnauthenticated());
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
      return 'Invalid verification code. Please try again.';
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
