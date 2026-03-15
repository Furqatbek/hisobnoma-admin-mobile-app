class FinancialSummary {
  final double totalBankBalance;
  final double totalCashBalance;
  final double arOutstanding;
  final double apOutstanding;
  final double netCashPosition;

  const FinancialSummary({
    required this.totalBankBalance,
    required this.totalCashBalance,
    required this.arOutstanding,
    required this.apOutstanding,
    required this.netCashPosition,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalBankBalance: (json['totalBankBalance'] as num?)?.toDouble() ?? 0,
      totalCashBalance: (json['totalCashBalance'] as num?)?.toDouble() ?? 0,
      arOutstanding: (json['arOutstanding'] as num?)?.toDouble() ?? 0,
      apOutstanding: (json['apOutstanding'] as num?)?.toDouble() ?? 0,
      netCashPosition: (json['netCashPosition'] as num?)?.toDouble() ?? 0,
    );
  }
}
