class SyncCategory {
  final int id;
  final String name;
  final int? parentId;
  final int sortOrder;
  final bool active;
  final DateTime updatedAt;

  const SyncCategory({
    required this.id,
    required this.name,
    this.parentId,
    required this.sortOrder,
    required this.active,
    required this.updatedAt,
  });

  factory SyncCategory.fromJson(Map<String, dynamic> json) {
    return SyncCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      parentId: json['parentId'] as int?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toDbRow() => {
    'id': id,
    'name': name,
    'parent_id': parentId,
    'sort_order': sortOrder,
    'active': active ? 1 : 0,
    'updated_at': updatedAt.toIso8601String(),
  };
}
