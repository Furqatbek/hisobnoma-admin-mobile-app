class DeliveryRegion {
  final int id;
  final String name;
  final String code;
  final String description;
  final bool active;
  final int sortOrder;
  final int villageCount;

  const DeliveryRegion({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.active,
    required this.sortOrder,
    required this.villageCount,
  });

  factory DeliveryRegion.fromJson(Map<String, dynamic> json) {
    return DeliveryRegion(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      villageCount: json['villageCount'] as int? ?? 0,
    );
  }
}
