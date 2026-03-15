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

  Future<void> login({required String phone, required String code}) async {
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
      emit(AuthError(message: e.toString()));
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
}
