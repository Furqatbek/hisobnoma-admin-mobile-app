class QuickSaleResponse {
  final int id;
  final String transactionNumber;
  final String transactionType;
  final String status;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final DateTime? completedAt;

  const QuickSaleResponse({
    required this.id,
    required this.transactionNumber,
    required this.transactionType,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    this.completedAt,
  });

  factory QuickSaleResponse.fromJson(Map<String, dynamic> json) {
    return QuickSaleResponse(
      id: json['id'] as int,
      transactionNumber: json['transactionNumber'] as String,
      transactionType: json['transactionType'] as String,
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  bool get isCompleted => status == 'COMPLETED';
}
