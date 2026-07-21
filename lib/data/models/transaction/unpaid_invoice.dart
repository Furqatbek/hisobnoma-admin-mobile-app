/// Unpaid invoice from the AR invoices API
class UnpaidInvoice {
  final int id;
  final String invoiceNumber;
  final String invoiceDate;
  final String dueDate;
  final String status;
  final String? posTransactionNumber;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;
  final String currency;
  final bool overdue;
  final int daysOverdue;
  final String? notes;
  final List<InvoiceLine> lines;
  final DateTime createdAt;

  const UnpaidInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.status,
    this.posTransactionNumber,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceDue,
    required this.currency,
    required this.overdue,
    required this.daysOverdue,
    this.notes,
    required this.lines,
    required this.createdAt,
  });

  factory UnpaidInvoice.fromJson(Map<String, dynamic> json) {
    return UnpaidInvoice(
      id: json['id'] as int,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      invoiceDate: json['invoiceDate'] as String? ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      status: json['status'] as String? ?? '',
      posTransactionNumber: json['posTransactionNumber'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'UZS',
      overdue: json['overdue'] as bool? ?? false,
      daysOverdue: (json['daysOverdue'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      lines: (json['lines'] as List? ?? [])
          .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Line item in an unpaid invoice
class InvoiceLine {
  final int id;
  final String productName;
  final String productSku;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final double discountAmount;

  const InvoiceLine({
    required this.id,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.discountAmount,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      id: json['id'] as int,
      productName: json['productName'] as String? ?? '',
      productSku: json['productSku'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
