/// Customer balance from the AR reports API
class CustomerBalance {
  final int customerId;
  final String customerCode;
  final String customerName;
  final double outstandingInvoices;
  final double availableCredits;
  final double netBalance;
  final double availableCreditLimit;
  final bool overCreditLimit;
  final bool onCreditHold;
  final String? lastInvoiceDate;
  final int? paymentTerms;

  const CustomerBalance({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.outstandingInvoices,
    required this.availableCredits,
    required this.netBalance,
    required this.availableCreditLimit,
    required this.overCreditLimit,
    required this.onCreditHold,
    this.lastInvoiceDate,
    this.paymentTerms,
  });

  factory CustomerBalance.fromJson(Map<String, dynamic> json) {
    return CustomerBalance(
      customerId: json['customerId'] as int,
      customerCode: json['customerCode'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      outstandingInvoices:
          (json['outstandingInvoices'] as num?)?.toDouble() ?? 0,
      availableCredits: (json['availableCredits'] as num?)?.toDouble() ?? 0,
      netBalance: (json['netBalance'] as num?)?.toDouble() ?? 0,
      availableCreditLimit:
          (json['availableCreditLimit'] as num?)?.toDouble() ?? 0,
      overCreditLimit: json['overCreditLimit'] as bool? ?? false,
      onCreditHold: json['onCreditHold'] as bool? ?? false,
      lastInvoiceDate: json['lastInvoiceDate'] as String?,
      paymentTerms: json['paymentTerms'] as int?,
    );
  }
}

/// Response wrapper for the customer balance report
class CustomerBalanceReport {
  final String reportDate;
  final List<CustomerBalance> customerBalances;
  final double totalReceivables;
  final double totalCredits;
  final double totalNetBalance;
  final int customerCount;

  const CustomerBalanceReport({
    required this.reportDate,
    required this.customerBalances,
    required this.totalReceivables,
    required this.totalCredits,
    required this.totalNetBalance,
    required this.customerCount,
  });

  factory CustomerBalanceReport.fromJson(Map<String, dynamic> json) {
    return CustomerBalanceReport(
      reportDate: json['reportDate'] as String? ?? '',
      customerBalances: (json['customerBalances'] as List? ?? [])
          .map((e) => CustomerBalance.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalReceivables:
          (json['totalReceivables'] as num?)?.toDouble() ?? 0,
      totalCredits: (json['totalCredits'] as num?)?.toDouble() ?? 0,
      totalNetBalance: (json['totalNetBalance'] as num?)?.toDouble() ?? 0,
      customerCount: json['customerCount'] as int? ?? 0,
    );
  }
}
