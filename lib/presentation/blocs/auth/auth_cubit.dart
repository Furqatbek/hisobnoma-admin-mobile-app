import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(const AuthAuthenticated());
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String phone, required String code}) async {
    emit(const AuthLoading());
    try {
      final data = await _authRepository.login(phone: phone, code: code);
      emit(AuthAuthenticated(
        userId: data['userId'] as int?,
        permissions: (data['permissions'] as List?)?.cast<String>(),
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      // Clear local state even if API call fails
      emit(const AuthUnauthenticated());
    }
  }
}
