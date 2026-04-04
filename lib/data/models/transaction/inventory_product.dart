/// Product from the inventory API (/inventory/products)
class InventoryProduct {
  final int id;
  final String sku;
  final String barcode;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final String? brandName;
  final String baseUomCode;
  final String baseUomName;
  final double costPrice;
  final double sellingPrice;
  final bool trackInventory;
  final bool active;
  final double margin;
  final double markup;
  final double stockQuantity;

  const InventoryProduct({
    required this.id,
    required this.sku,
    required this.barcode,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.brandName,
    required this.baseUomCode,
    required this.baseUomName,
    required this.costPrice,
    required this.sellingPrice,
    required this.trackInventory,
    required this.active,
    required this.margin,
    required this.markup,
    required this.stockQuantity,
  });

  factory InventoryProduct.fromJson(Map<String, dynamic> json) {
    return InventoryProduct(
      id: json['id'] as int,
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      brandName: json['brandName'] as String?,
      baseUomCode: json['baseUomCode'] as String? ?? 'UNIT',
      baseUomName: json['baseUomName'] as String? ?? '',
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      trackInventory: json['trackInventory'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      margin: (json['margin'] as num?)?.toDouble() ?? 0,
      markup: (json['markup'] as num?)?.toDouble() ?? 0,
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0,
    );
  }
}
