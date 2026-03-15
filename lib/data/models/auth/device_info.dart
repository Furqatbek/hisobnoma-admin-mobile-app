class DeviceInfo {
  final int id;
  final String deviceId;
  final String platform;
  final String deviceName;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final bool active;
  final DateTime? lastActiveAt;

  const DeviceInfo({
    required this.id,
    required this.deviceId,
    required this.platform,
    required this.deviceName,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
    required this.active,
    this.lastActiveAt,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] as int,
      deviceId: json['deviceId'] as String,
      platform: json['platform'] as String,
      deviceName: json['deviceName'] as String,
      deviceModel: json['deviceModel'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      active: json['active'] as bool? ?? true,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'] as String)
          : null,
    );
  }
}
