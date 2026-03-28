part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Users list loaded, waiting for account selection + PIN
class AuthUsersLoaded extends AuthState {
  final List<UserAccount> users;

  const AuthUsersLoaded({required this.users});

  @override
  List<Object?> get props => [users];
}

/// A user account is selected, waiting for PIN entry
class AuthAccountSelected extends AuthState {
  final List<UserAccount> users;
  final UserAccount selectedUser;

  const AuthAccountSelected({
    required this.users,
    required this.selectedUser,
  });

  @override
  List<Object?> get props => [users, selectedUser];
}

class AuthAuthenticated extends AuthState {
  final int? userId;
  final List<String>? permissions;

  const AuthAuthenticated({this.userId, this.permissions});

  @override
  List<Object?> get props => [userId, permissions];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final List<UserAccount>? users;
  final UserAccount? selectedUser;

  const AuthError({
    required this.message,
    this.users,
    this.selectedUser,
  });

  @override
  List<Object?> get props => [message, users, selectedUser];
}
