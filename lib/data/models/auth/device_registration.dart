class DeviceRegistration {
  final String deviceId;
  final String fcmToken;
  final String platform; // ANDROID, IOS, WEB
  final String deviceName;
  final String deviceModel;
  final String osVersion;
  final String appVersion;

  const DeviceRegistration({
    required this.deviceId,
    required this.fcmToken,
    required this.platform,
    required this.deviceName,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': platform,
        'deviceName': deviceName,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'appVersion': appVersion,
      };
}
