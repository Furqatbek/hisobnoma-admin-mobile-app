/// Detailed transaction from /pos/transactions/{id}
class SaleDetail {
  final int id;
  final String transactionNumber;
  final String transactionType;
  final String status;
  final String? cashierName;
  final String? terminalName;
  final String? locationName;
  final int? customerId;
  final String? customerName;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final double balanceDue;
  final int itemCount;
  final List<SaleDetailLine> lines;
  final List<SaleDetailPayment> payments;
  final DateTime createdAt;
  final DateTime? completedAt;

  const SaleDetail({
    required this.id,
    required this.transactionNumber,
    required this.transactionType,
    required this.status,
    this.cashierName,
    this.terminalName,
    this.locationName,
    this.customerId,
    this.customerName,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.balanceDue,
    required this.itemCount,
    required this.lines,
    required this.payments,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'COMPLETED';

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    return SaleDetail(
      id: json['id'] as int,
      transactionNumber: json['transactionNumber'] as String? ?? '',
      transactionType: json['transactionType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      cashierName: json['cashierName'] as String?,
      terminalName: json['terminalName'] as String?,
      locationName: json['locationName'] as String?,
      customerId: json['customerId'] as int?,
      customerName: json['customerName'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0,
      balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      lines: (json['lines'] as List? ?? [])
          .map((e) => SaleDetailLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List? ?? [])
          .map((e) => SaleDetailPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}

/// Line item in a sale transaction
class SaleDetailLine {
  final int id;
  final String productName;
  final String productCode;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final double discountAmount;
  final String? uomName;
  final String? saleUomName;
  final double? saleQuantity;

  const SaleDetailLine({
    required this.id,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.discountAmount,
    this.uomName,
    this.saleUomName,
    this.saleQuantity,
  });

  factory SaleDetailLine.fromJson(Map<String, dynamic> json) {
    return SaleDetailLine(
      id: json['id'] as int,
      productName: json['productName'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      uomName: json['uomName'] as String?,
      saleUomName: json['saleUomName'] as String?,
      saleQuantity: (json['saleQuantity'] as num?)?.toDouble(),
    );
  }
}

/// Payment entry in a sale transaction
class SaleDetailPayment {
  final int id;
  final String paymentType;
  final String status;
  final double amount;
  final double changeAmount;
  final String currency;
  final DateTime? processedAt;

  const SaleDetailPayment({
    required this.id,
    required this.paymentType,
    required this.status,
    required this.amount,
    required this.changeAmount,
    required this.currency,
    this.processedAt,
  });

  factory SaleDetailPayment.fromJson(Map<String, dynamic> json) {
    return SaleDetailPayment(
      id: json['id'] as int,
      paymentType: json['paymentType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'UZS',
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'] as String)
          : null,
    );
  }
}
