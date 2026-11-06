/// Models for Telegram account linking (raw Map responses from
/// /api/v1/telegram/*, not ApiResponse-wrapped).

class TelegramStatus {
  final bool linked;
  final String botUsername;
  final String linkedAt;

  const TelegramStatus({
    required this.linked,
    required this.botUsername,
    required this.linkedAt,
  });

  factory TelegramStatus.fromJson(Map<String, dynamic> json) {
    return TelegramStatus(
      linked: json['linked'] == true,
      botUsername: (json['botUsername'] ?? '').toString(),
      linkedAt: (json['linkedAt'] ?? '').toString(),
    );
  }
}

class TelegramLinkCode {
  final String code;
  final String botUsername;
  final int expiresInSeconds;

  const TelegramLinkCode({
    required this.code,
    required this.botUsername,
    required this.expiresInSeconds,
  });

  factory TelegramLinkCode.fromJson(Map<String, dynamic> json) {
    return TelegramLinkCode(
      code: (json['code'] ?? '').toString(),
      botUsername: (json['botUsername'] ?? '').toString(),
      // The backend returns this as a string ("600").
      expiresInSeconds:
          int.tryParse((json['expiresInSeconds'] ?? '600').toString()) ?? 600,
    );
  }
}
