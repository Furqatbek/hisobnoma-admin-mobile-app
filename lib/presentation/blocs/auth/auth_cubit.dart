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
      await loadUsers();
    }
  }

  /// Fetch available user accounts
  Future<void> loadUsers() async {
    try {
      final users = await _authRepository.getUsers();
      emit(AuthUsersLoaded(users: users));
    } catch (e) {
      emit(AuthError(message: _parseError(e)));
    }
  }

  /// User selects an account from the list
  void selectAccount(UserAccount user) {
    final currentState = state;
    final users = currentState is AuthUsersLoaded
        ? currentState.users
        : currentState is AuthAccountSelected
            ? currentState.users
            : currentState is AuthError
                ? currentState.users ?? []
                : <UserAccount>[];
    emit(AuthAccountSelected(users: users, selectedUser: user));
  }

  /// Go back to account selection
  void backToAccountSelection() {
    final currentState = state;
    final users = currentState is AuthAccountSelected
        ? currentState.users
        : currentState is AuthError
            ? currentState.users ?? []
            : <UserAccount>[];
    emit(AuthUsersLoaded(users: users));
  }

  /// Login with username + pin
  Future<void> login({
    required String username,
    required String pin,
  }) async {
    final currentState = state;
    final users = currentState is AuthAccountSelected
        ? currentState.users
        : currentState is AuthError
            ? currentState.users
            : null;
    final selectedUser = currentState is AuthAccountSelected
        ? currentState.selectedUser
        : currentState is AuthError
            ? currentState.selectedUser
            : null;

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
      emit(AuthError(
        message: _parseError(e),
        users: users,
        selectedUser: selectedUser,
      ));
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
    await loadUsers();
  }

  /// Called when the server rejects our refresh token (session truly expired).
  /// Routes the user back to the login screen instead of leaving them stranded
  /// on screens that silently fail every request. Does NOT call the logout API
  /// (that request would just 401 again).
  Future<void> handleSessionExpired() async {
    // If we are already in the login flow, there is nothing to do.
    if (state is AuthUnauthenticated ||
        state is AuthUsersLoaded ||
        state is AuthAccountSelected) {
      return;
    }
    emit(const AuthUnauthenticated());
    await loadUsers();
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
