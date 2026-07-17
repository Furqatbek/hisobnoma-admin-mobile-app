import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart';
import 'package:hisobnoma/data/repositories/device_repository.dart';

/// Bridges the native APNs layer (see ios/Runner/AppDelegate.swift) to the
/// backend: requests permission, receives the device token, registers it for
/// the logged-in user, and surfaces notification taps for routing.
///
/// iOS-only for now. On platforms without the native handler (Android today,
/// web) the channel calls throw and are swallowed, so this is a safe no-op
/// there — Android will get its own FCM implementation later.
class PushNotificationService {
  static const _channel = MethodChannel('hisobnoma/push');

  final DeviceRepository _deviceRepository;

  String? _token;

  /// Invoked when the user taps a notification. Set by the app to route to the
  /// relevant screen using the notification's `data` payload.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  PushNotificationService({required DeviceRepository deviceRepository})
      : _deviceRepository = deviceRepository {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onToken':
        _token = call.arguments as String?;
        await _registerToken();
        break;
      case 'onTokenError':
        // Registration with APNs failed natively; nothing to do — we simply
        // won't have a token this session.
        break;
      case 'onNotificationTap':
        onNotificationTap?.call(_asStringMap(call.arguments));
        break;
    }
    return null;
  }

  /// Ask the user for notification permission and start APNs registration.
  /// Call after a successful login. The token arrives asynchronously via the
  /// native `onToken` callback, which then registers it with the backend.
  Future<void> enable() async {
    try {
      await _channel.invokeMethod<bool>('requestPermissionAndRegister');
      // If a token was already obtained earlier this session, (re)register it
      // now that the user is authenticated.
      await _registerToken();
    } on PlatformException catch (_) {
      // Permission flow failed — ignore.
    } on MissingPluginException catch (_) {
      // No native handler (non-iOS platform) — no-op.
    }
  }

  /// Remove this device's token on logout so it stops receiving pushes.
  Future<void> disable() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    try {
      await _deviceRepository.removePushToken(token: token);
    } catch (_) {
      // Best-effort; ignore failures on logout.
    }
  }

  Future<void> _registerToken() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    try {
      await _deviceRepository.registerPushToken(
        token: token,
        platform: 'ios',
        // Debug builds use the APNs sandbox; release/TestFlight/App Store use
        // production. The backend must send to the matching host.
        environment: kReleaseMode ? 'production' : 'sandbox',
      );
    } catch (_) {
      // Backend not reachable / endpoint not live yet — will retry on the next
      // enable() (e.g. next login or app start).
    }
  }

  Map<String, dynamic> _asStringMap(Object? arguments) {
    if (arguments is Map) {
      return arguments.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }
}
