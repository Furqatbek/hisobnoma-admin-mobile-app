import 'package:hisobnoma/data/models/alert/alert.dart';

class AlertPreference {
  final int id;
  final AlertType alertType;
  final bool pushEnabled;
  final bool inAppEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final int? thresholdValue;

  const AlertPreference({
    required this.id,
    required this.alertType,
    required this.pushEnabled,
    required this.inAppEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    this.thresholdValue,
  });

  factory AlertPreference.fromJson(Map<String, dynamic> json) {
    return AlertPreference(
      id: json['id'] as int,
      alertType: AlertType.fromString(json['alertType'] as String),
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      inAppEnabled: json['inAppEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? false,
      smsEnabled: json['smsEnabled'] as bool? ?? false,
      thresholdValue: json['thresholdValue'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'pushEnabled': pushEnabled,
    'inAppEnabled': inAppEnabled,
    'emailEnabled': emailEnabled,
    'smsEnabled': smsEnabled,
    if (thresholdValue != null) 'thresholdValue': thresholdValue,
  };

  AlertPreference copyWith({
    bool? pushEnabled,
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    int? thresholdValue,
  }) {
    return AlertPreference(
      id: id,
      alertType: alertType,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      thresholdValue: thresholdValue ?? this.thresholdValue,
    );
  }
}
