import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisobnoma/data/repositories/device_repository.dart';

/// Bridges the native APNs layer (see ios/Runner/AppDelegate.swift) to the
/// backend: requests permission, receives the device token, registers it for
/// the logged-in user, and surfaces notification taps for routing.
///
/// Permission strategy: we do NOT fire the iOS system dialog at login. Instead
/// [enabledPreference] holds the user's intent (a master toggle in Settings,
/// default on) and the OS prompt is triggered gently — after the user's first
/// sale ([shouldPrimeAfterSale] + [acceptPriming]) or when they flip the
/// Settings toggle ([setEnabledPreference]). On later logins we only
/// re-register silently if the user already granted permission before.
///
/// iOS-only for now. On platforms without the native handler (Android today,
/// web) the channel calls throw and are swallowed, so this is a safe no-op
/// there — Android will get its own FCM implementation later.
class PushNotificationService {
  static const _channel = MethodChannel('hisobnoma/push');

  /// Master toggle intent — whether the user wants push notifications.
  static const _enabledKey = 'notifications_enabled';

  /// Whether we have ever triggered the iOS permission dialog. Gates the
  /// after-first-sale priming so we only ask once.
  static const _promptedKey = 'push_permission_prompted';

  /// Whether the after-first-sale priming sheet has been shown (either choice),
  /// so a user who tapped "Not now" isn't nagged on every subsequent sale.
  static const _primingShownKey = 'push_priming_shown';

  final DeviceRepository _deviceRepository;
  final SharedPreferences _preferences;

  String? _token;

  /// Invoked when the user taps a notification. Set by the app to route to the
  /// relevant screen using the notification's `data` payload.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  PushNotificationService({
    required DeviceRepository deviceRepository,
    required SharedPreferences preferences,
  })  : _deviceRepository = deviceRepository,
        _preferences = preferences {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// The master toggle intent (Settings switch). Defaults to on.
  bool get enabledPreference => _preferences.getBool(_enabledKey) ?? true;

  bool get _permissionPrompted => _preferences.getBool(_promptedKey) ?? false;

  bool get _primingShown => _preferences.getBool(_primingShownKey) ?? false;

  /// True when we should show the priming sheet after a sale: the user wants
  /// notifications, we've never asked the OS, and we haven't primed yet.
  bool get shouldPrimeAfterSale =>
      enabledPreference && !_permissionPrompted && !_primingShown;

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

  /// Called after login. Only re-registers silently for users who already
  /// granted permission — it never triggers the OS dialog, so new users aren't
  /// prompted cold. New users are asked after their first sale instead.
  Future<void> syncOnLogin() async {
    if (enabledPreference && _permissionPrompted) {
      await _enable();
    }
  }

  /// The user accepted the after-first-sale priming. Records intent, marks the
  /// OS as prompted, and triggers the real permission request + registration.
  Future<void> acceptPriming() async {
    await _preferences.setBool(_enabledKey, true);
    await _preferences.setBool(_primingShownKey, true);
    await _preferences.setBool(_promptedKey, true);
    await _enable();
  }

  /// The user tapped "Not now" on the priming sheet. Don't ask again after
  /// sales; they can still enable later from Settings.
  Future<void> declinePriming() async {
    await _preferences.setBool(_primingShownKey, true);
  }

  /// Master toggle handler (Settings switch). On enable, requests permission
  /// (if not asked before) and registers the token; on disable, removes it.
  Future<void> setEnabledPreference(bool value) async {
    await _preferences.setBool(_enabledKey, value);
    if (value) {
      await _preferences.setBool(_promptedKey, true);
      await _preferences.setBool(_primingShownKey, true);
      await _enable();
    } else {
      await disable();
    }
  }

  /// Ask the user for notification permission and start APNs registration. The
  /// token arrives asynchronously via the native `onToken` callback, which then
  /// registers it with the backend.
  Future<void> _enable() async {
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

  /// Remove this device's token on logout so it stops receiving pushes. Keeps
  /// the user's master-toggle intent so the next login re-registers.
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
