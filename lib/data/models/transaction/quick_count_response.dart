class QuickCountResponse {
  final int productId;
  final String productName;
  final String sku;
  final int locationId;
  final int systemQuantity;
  final int countedQuantity;
  final int variance;
  final double variancePercent;

  const QuickCountResponse({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.locationId,
    required this.systemQuantity,
    required this.countedQuantity,
    required this.variance,
    required this.variancePercent,
  });

  factory QuickCountResponse.fromJson(Map<String, dynamic> json) {
    return QuickCountResponse(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      sku: json['sku'] as String,
      locationId: json['locationId'] as int,
      systemQuantity: (json['systemQuantity'] as num?)?.toInt() ?? 0,
      countedQuantity: (json['countedQuantity'] as num?)?.toInt() ?? 0,
      variance: (json['variance'] as num?)?.toInt() ?? 0,
      variancePercent: (json['variancePercent'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get hasVariance => variance != 0;
}
