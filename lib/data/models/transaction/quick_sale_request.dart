class QuickSaleRequest {
  final int terminalId;
  final int? customerId;
  final String? customerName;
  final List<QuickSaleItem> items;
  final String paymentType;
  final double tenderedAmount;
  final String? notes;

  const QuickSaleRequest({
    required this.terminalId,
    this.customerId,
    this.customerName,
    required this.items,
    required this.paymentType,
    required this.tenderedAmount,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'terminalId': terminalId,
        if (customerId != null) 'customerId': customerId,
        if (customerName != null) 'customerName': customerName,
        'items': items.map((e) => e.toJson()).toList(),
        'paymentType': paymentType,
        'tenderedAmount': tenderedAmount,
        if (notes != null) 'notes': notes,
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
