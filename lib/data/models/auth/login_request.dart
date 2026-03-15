class LoginRequest {
  final String phone;
  final String code;

  const LoginRequest({required this.phone, required this.code});

  Map<String, dynamic> toJson() => {'phone': phone, 'code': code};
}
