class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final int userId;
  final int tenantId;
  final List<String> permissions;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.userId,
    required this.tenantId,
    required this.permissions,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int? ?? 86400,
      userId: user['id'] as int? ?? json['userId'] as int? ?? 0,
      tenantId: user['tenantId'] as int? ?? json['tenantId'] as int? ?? 0,
      permissions:
          (user['permissions'] as List?)?.cast<String>() ??
          (json['permissions'] as List?)?.cast<String>() ??
          [],
    );
  }
}
