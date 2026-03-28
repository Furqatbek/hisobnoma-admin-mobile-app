class LoginRequest {
  final String username;
  final String pin;

  const LoginRequest({required this.username, required this.pin});

  Map<String, dynamic> toJson() => {'username': username, 'pin': pin};
}
