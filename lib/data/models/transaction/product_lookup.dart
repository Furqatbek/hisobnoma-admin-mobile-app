class ProductLookup {
  final int productId;
  final String sku;
  final String barcode;
  final String name;
  final double sellingPrice;
  final double costPrice;
  final int totalStock;
  final String category;
  final String uom;
  final bool trackInventory;
  final List<StockByLocation> stockByLocation;

  const ProductLookup({
    required this.productId,
    required this.sku,
    required this.barcode,
    required this.name,
    required this.sellingPrice,
    required this.costPrice,
    required this.totalStock,
    required this.category,
    required this.uom,
    required this.trackInventory,
    required this.stockByLocation,
  });

  factory ProductLookup.fromJson(Map<String, dynamic> json) {
    return ProductLookup(
      productId: (json['productId'] ?? json['id']) as int,
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      totalStock: (json['totalStock'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      uom: json['uom'] as String? ?? 'pcs',
      trackInventory: json['trackInventory'] as bool? ?? true,
      stockByLocation:
          (json['stockByLocation'] as List?)
              ?.map((e) => StockByLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class StockByLocation {
  final int locationId;
  final String locationName;
  final int quantityOnHand;
  final int quantityReserved;
  final int quantityAvailable;

  const StockByLocation({
    required this.locationId,
    required this.locationName,
    required this.quantityOnHand,
    required this.quantityReserved,
    required this.quantityAvailable,
  });

  factory StockByLocation.fromJson(Map<String, dynamic> json) {
    return StockByLocation(
      locationId: json['locationId'] as int,
      locationName: json['locationName'] as String,
      quantityOnHand: (json['quantityOnHand'] as num?)?.toInt() ?? 0,
      quantityReserved: (json['quantityReserved'] as num?)?.toInt() ?? 0,
      quantityAvailable: (json['quantityAvailable'] as num?)?.toInt() ?? 0,
    );
  }
}
