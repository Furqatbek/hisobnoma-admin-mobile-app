class PosTerminal {
  final int id;
  final String terminalCode;
  final String name;
  final int locationId;
  final String locationName;
  final bool active;
  final bool cashDrawerEnabled;
  final bool allowOffline;

  const PosTerminal({
    required this.id,
    required this.terminalCode,
    required this.name,
    required this.locationId,
    required this.locationName,
    required this.active,
    required this.cashDrawerEnabled,
    required this.allowOffline,
  });

  factory PosTerminal.fromJson(Map<String, dynamic> json) {
    return PosTerminal(
      id: json['id'] as int,
      terminalCode: json['terminalCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      locationId: json['locationId'] as int? ?? 0,
      locationName: json['locationName'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      cashDrawerEnabled: json['cashDrawerEnabled'] as bool? ?? false,
      allowOffline: json['allowOffline'] as bool? ?? false,
    );
  }
}
