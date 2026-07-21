/// A sale transaction record from the POS transactions API
class SaleRecord {
  final int id;
  final String transactionNumber;
  final String transactionType;
  final String status;
  final String? cashierName;
  final int? customerId;
  final String? customerName;
  final String? terminalName;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final int itemCount;
  final int lineCount;
  final String? paymentType;
  final DateTime createdAt;
  final DateTime? completedAt;

  const SaleRecord({
    required this.id,
    required this.transactionNumber,
    required this.transactionType,
    required this.status,
    this.cashierName,
    this.customerId,
    this.customerName,
    this.terminalName,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.itemCount,
    required this.lineCount,
    this.paymentType,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'COMPLETED';

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    // Extract payment type from first payment entry
    String? paymentType;
    final payments = json['payments'] as List?;
    if (payments != null && payments.isNotEmpty) {
      paymentType =
          (payments[0] as Map<String, dynamic>)['paymentType'] as String?;
    }

    return SaleRecord(
      id: json['id'] as int,
      transactionNumber: json['transactionNumber'] as String? ?? '',
      transactionType: json['transactionType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      cashierName: json['cashierName'] as String?,
      customerId: json['customerId'] as int?,
      customerName: json['customerName'] as String?,
      terminalName: json['terminalName'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      lineCount: (json['lineCount'] as num?)?.toInt() ?? 0,
      paymentType: paymentType,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
