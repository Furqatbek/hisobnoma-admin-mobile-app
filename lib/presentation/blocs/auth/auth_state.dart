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

/// OTP code has been sent, waiting for user to enter it
class AuthCodeSent extends AuthState {
  final String phone;

  const AuthCodeSent({required this.phone});

  @override
  List<Object?> get props => [phone];
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
  final String? phone; // preserve phone so user can retry

  const AuthError({required this.message, this.phone});

  @override
  List<Object?> get props => [message, phone];
}
