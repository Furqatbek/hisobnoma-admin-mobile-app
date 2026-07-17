import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Channel used to talk to Dart about push tokens and notification taps.
  /// Name must match `PushNotificationService._channel` on the Dart side.
  private var pushChannel: FlutterMethodChannel?

  /// The most recent APNs device token (hex). Cached so Dart can pull it even
  /// if registration completed before the channel existed.
  private var cachedToken: String?

  /// A notification tap that arrived before the Flutter channel was ready
  /// (e.g. cold launch from a tap). Delivered once the channel comes up.
  private var pendingTapData: [String: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Receive foreground-presentation and tap callbacks.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Set up the push method channel on the implicit engine's messenger.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HisobnomaPush") {
      let channel = FlutterMethodChannel(
        name: "hisobnoma/push",
        binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleMethodCall(call, result: result)
      }
      pushChannel = channel

      // Flush anything captured before the channel existed.
      if let token = cachedToken {
        channel.invokeMethod("onToken", arguments: token)
      }
      if let tap = pendingTapData {
        channel.invokeMethod("onNotificationTap", arguments: tap)
        pendingTapData = nil
      }
    }
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermissionAndRegister":
      // Ask the user; on grant, register with APNs to obtain a device token.
      UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .badge, .sound]
      ) { granted, _ in
        DispatchQueue.main.async {
          if granted {
            UIApplication.shared.registerForRemoteNotifications()
          }
          result(granted)
        }
      }
    case "getToken":
      result(cachedToken)
    case "clearBadge":
      // Clear the app-icon badge (e.g. when the user opens the Alerts center).
      if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(0)
      } else {
        UIApplication.shared.applicationIconBadgeNumber = 0
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Extract the app's routing payload from a notification. The backend sends
  /// `type`/`id`/`route` at the TOP LEVEL alongside `aps` (not nested under a
  /// `data` key), so collect every top-level key except Apple's `aps`.
  private func routingData(from userInfo: [AnyHashable: Any]) -> [String: Any] {
    var data: [String: Any] = [:]
    for (key, value) in userInfo {
      if let k = key as? String, k != "aps" {
        data[k] = value
      }
    }
    return data
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    cachedToken = token
    pushChannel?.invokeMethod("onToken", arguments: token)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    pushChannel?.invokeMethod("onTokenError", arguments: error.localizedDescription)
  }

  /// Show notifications while the app is in the foreground (iOS otherwise
  /// suppresses remote-push banners when the app is open).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // .banner/.list are iOS 14+; fall back to .alert on iOS 13.
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  /// Handle a tap on a notification — forward its `data` payload to Dart for
  /// routing. If the channel isn't up yet (cold launch), stash it.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    let data = routingData(from: userInfo)
    if let channel = pushChannel {
      channel.invokeMethod("onNotificationTap", arguments: data)
    } else {
      pendingTapData = data
    }
    completionHandler()
  }
}
