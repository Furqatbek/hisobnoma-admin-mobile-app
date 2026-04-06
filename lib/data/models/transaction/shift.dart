/// POS shift model matching GET /shifts response
class Shift {
  final int id;
  final String shiftNumber;
  final int terminalId;
  final String terminalCode;
  final String terminalName;
  final int cashierId;
  final String cashierName;
  final String status; // OPEN, CLOSED, RECONCILED
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? cashDifference;
  final double totalSales;
  final double totalReturns;
  final double totalDiscounts;
  final double totalTaxes;
  final double cashPayments;
  final double cardPayments;
  final double otherPayments;
  final int transactionCount;
  final int voidedCount;
  final int returnCount;
  final double cashIn;
  final double cashOut;
  final String? notes;

  const Shift({
    required this.id,
    required this.shiftNumber,
    required this.terminalId,
    required this.terminalCode,
    required this.terminalName,
    required this.cashierId,
    required this.cashierName,
    required this.status,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
    this.cashDifference,
    required this.totalSales,
    required this.totalReturns,
    required this.totalDiscounts,
    required this.totalTaxes,
    required this.cashPayments,
    required this.cardPayments,
    required this.otherPayments,
    required this.transactionCount,
    required this.voidedCount,
    required this.returnCount,
    required this.cashIn,
    required this.cashOut,
    this.notes,
  });

  bool get isOpen => status == 'OPEN';
  bool get isClosed => status == 'CLOSED';

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as int,
      shiftNumber: json['shiftNumber'] as String? ?? '',
      terminalId: json['terminalId'] as int? ?? 0,
      terminalCode: json['terminalCode'] as String? ?? '',
      terminalName: json['terminalName'] as String? ?? '',
      cashierId: json['cashierId'] as int? ?? 0,
      cashierName: json['cashierName'] as String? ?? '',
      status: json['status'] as String? ?? 'CLOSED',
      openedAt: DateTime.parse(json['openedAt'] as String),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
      openingCash: (json['openingCash'] as num?)?.toDouble() ?? 0,
      closingCash: (json['closingCash'] as num?)?.toDouble(),
      expectedCash: (json['expectedCash'] as num?)?.toDouble(),
      cashDifference: (json['cashDifference'] as num?)?.toDouble(),
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
      totalReturns: (json['totalReturns'] as num?)?.toDouble() ?? 0,
      totalDiscounts: (json['totalDiscounts'] as num?)?.toDouble() ?? 0,
      totalTaxes: (json['totalTaxes'] as num?)?.toDouble() ?? 0,
      cashPayments: (json['cashPayments'] as num?)?.toDouble() ?? 0,
      cardPayments: (json['cardPayments'] as num?)?.toDouble() ?? 0,
      otherPayments: (json['otherPayments'] as num?)?.toDouble() ?? 0,
      transactionCount: json['transactionCount'] as int? ?? 0,
      voidedCount: json['voidedCount'] as int? ?? 0,
      returnCount: json['returnCount'] as int? ?? 0,
      cashIn: (json['cashIn'] as num?)?.toDouble() ?? 0,
      cashOut: (json['cashOut'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
    );
  }
}
