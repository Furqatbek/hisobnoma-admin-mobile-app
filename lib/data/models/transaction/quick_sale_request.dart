class QuickSaleRequest {
  final int terminalId;
  final int? customerId;
  final List<QuickSaleItem> items;
  final String paymentType;
  final double tenderedAmount;
  final String? notes;

  const QuickSaleRequest({
    required this.terminalId,
    this.customerId,
    required this.items,
    required this.paymentType,
    required this.tenderedAmount,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'terminalId': terminalId,
        'customerId': customerId,
        'items': items.map((e) => e.toJson()).toList(),
        'paymentType': paymentType,
        'tenderedAmount': tenderedAmount,
        if (notes != null) 'notes': notes,
      };
}

class QuickSaleItem {
  final int productId;
  final int? variantId;
  final int quantity;
  final double unitPrice;
  final double discountAmount;

  const QuickSaleItem({
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'discountAmount': discountAmount,
      };

  double get totalAmount => (unitPrice * quantity) - discountAmount;
}
