class SyncProduct {
  final int id;
  final String sku;
  final String? barcode;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final double sellingPrice;
  final double costPrice;
  final String unitOfMeasure;
  final bool trackInventory;
  final bool active;
  final DateTime updatedAt;

  const SyncProduct({
    required this.id,
    required this.sku,
    this.barcode,
    required this.name,
    this.categoryId,
    this.categoryName,
    required this.sellingPrice,
    required this.costPrice,
    required this.unitOfMeasure,
    required this.trackInventory,
    required this.active,
    required this.updatedAt,
  });

  factory SyncProduct.fromJson(Map<String, dynamic> json) {
    return SyncProduct(
      id: json['id'] as int,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      name: json['name'] as String,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      unitOfMeasure: json['unitOfMeasure'] as String? ?? 'pcs',
      trackInventory: json['trackInventory'] as bool? ?? true,
      active: json['active'] as bool? ?? true,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert to local database row
  Map<String, dynamic> toDbRow() => {
        'id': id,
        'sku': sku,
        'barcode': barcode,
        'name': name,
        'category_id': categoryId,
        'category_name': categoryName,
        'selling_price': sellingPrice,
        'cost_price': costPrice,
        'unit_of_measure': unitOfMeasure,
        'track_inventory': trackInventory ? 1 : 0,
        'active': active ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };
}
