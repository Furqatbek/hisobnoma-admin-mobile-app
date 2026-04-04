/// A sale transaction record from the sales history API
class SaleRecord {
  final int id;
  final String transactionNumber;
  final String transactionType;
  final String status;
  final int? customerId;
  final String? customerName;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final String? paymentType;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;

  const SaleRecord({
    required this.id,
    required this.transactionNumber,
    required this.transactionType,
    required this.status,
    this.customerId,
    this.customerName,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    this.paymentType,
    this.notes,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'COMPLETED';

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      id: json['id'] as int,
      transactionNumber: json['transactionNumber'] as String? ?? '',
      transactionType: json['transactionType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      customerId: json['customerId'] as int?,
      customerName: json['customerName'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0,
      paymentType: json['paymentType'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
