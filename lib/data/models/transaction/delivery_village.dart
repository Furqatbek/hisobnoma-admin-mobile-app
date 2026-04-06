class DeliveryVillage {
  final int id;
  final int regionId;
  final String regionName;
  final String name;
  final String code;
  final String description;
  final bool active;
  final int sortOrder;

  const DeliveryVillage({
    required this.id,
    required this.regionId,
    required this.regionName,
    required this.name,
    required this.code,
    required this.description,
    required this.active,
    required this.sortOrder,
  });

  factory DeliveryVillage.fromJson(Map<String, dynamic> json) {
    return DeliveryVillage(
      id: json['id'] as int,
      regionId: json['regionId'] as int? ?? 0,
      regionName: json['regionName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
