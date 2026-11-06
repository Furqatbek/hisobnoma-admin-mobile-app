import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/data/models/telegram/telegram_models.dart';

/// Links the signed-in staff user's Telegram chat to their account so the
/// backend can message them (e.g. the debtors list). The flow: get a 6-digit
/// code, the user sends it to the bot in Telegram, the bot links the chat.
///
/// These endpoints return a raw Map, NOT the usual {success, data} envelope.
class TelegramRepository {
  final ApiClient _apiClient;

  TelegramRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Whether this user has linked Telegram, plus the bot's username.
  Future<TelegramStatus> getStatus() async {
    final response = await _apiClient.get(ApiEndpoints.telegramStatus);
    return TelegramStatus.fromJson(_asMap(response.data));
  }

  /// Generate a 6-digit link code (valid ~10 minutes). The user sends it to
  /// the bot as a plain message to complete linking.
  Future<TelegramLinkCode> generateLinkCode() async {
    final response = await _apiClient.post(ApiEndpoints.telegramLinkCode);
    return TelegramLinkCode.fromJson(_asMap(response.data));
  }

  /// Unlink Telegram from this user's account.
  Future<void> unlink() async {
    await _apiClient.delete(ApiEndpoints.telegramUnlink);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return const {};
  }
}
