class InventorySummary {
  final int totalSkuCount;
  final int activeSkuCount;
  final double totalInventoryValue;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiringCount;

  const InventorySummary({
    required this.totalSkuCount,
    required this.activeSkuCount,
    required this.totalInventoryValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.expiringCount,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      totalSkuCount: (json['totalSkuCount'] as num?)?.toInt() ?? 0,
      activeSkuCount: (json['activeSkuCount'] as num?)?.toInt() ?? 0,
      totalInventoryValue:
          (json['totalInventoryValue'] as num?)?.toDouble() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      outOfStockCount: (json['outOfStockCount'] as num?)?.toInt() ?? 0,
      expiringCount: (json['expiringCount'] as num?)?.toInt() ?? 0,
    );
  }
}
