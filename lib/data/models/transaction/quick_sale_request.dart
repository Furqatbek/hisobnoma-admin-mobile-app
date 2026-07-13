class QuickSaleRequest {
  final int terminalId;
  final int? customerId;
  final String? customerName;
  final List<QuickSaleItem> items;
  final String paymentType;
  final double tenderedAmount;
  final String? notes;
  final int? deliveryRegionId;
  final int? deliveryVillageId;

  /// Client-generated idempotency key (UUID). The backend records
  /// (tenant, clientRequestId) → transactionId and returns the original
  /// transaction on a repeat, so a retried sale never creates a duplicate.
  final String? clientRequestId;

  const QuickSaleRequest({
    required this.terminalId,
    this.customerId,
    this.customerName,
    required this.items,
    required this.paymentType,
    required this.tenderedAmount,
    this.notes,
    this.deliveryRegionId,
    this.deliveryVillageId,
    this.clientRequestId,
  });

  Map<String, dynamic> toJson() => {
        'terminalId': terminalId,
        if (customerId != null) 'customerId': customerId,
        if (customerName != null) 'customerName': customerName,
        'items': items.map((e) => e.toJson()).toList(),
        'paymentType': paymentType,
        'tenderedAmount': tenderedAmount,
        if (notes != null) 'notes': notes,
        if (deliveryRegionId != null) 'deliveryRegionId': deliveryRegionId,
        if (deliveryVillageId != null) 'deliveryVillageId': deliveryVillageId,
        if (clientRequestId != null) 'clientRequestId': clientRequestId,
      };
}

class QuickSaleItem {
  final int productId;
  final double quantity;
  final double unitPrice;
  final double discountAmount;

  const QuickSaleItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'discountAmount': discountAmount,
      };

  double get totalAmount => (unitPrice * quantity) - discountAmount;
}
