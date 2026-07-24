/// Models for the finance/HR mobile features (expenses, debtor payments,
/// salary/advance). Contracts: docs/api/MOBILE_MODULE_API.md.

/// An employee, for the salary/advance payee picker.
class Employee {
  final int id;
  final String name;
  final String? position;

  const Employee({required this.id, required this.name, this.position});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['fullName'] ?? '') as String,
      position: (json['position'] ?? json['role'] ?? json['title']) as String?,
    );
  }
}

/// Method for an incoming debtor payment. Values match the backend's allowed
/// set (CASH | CREDIT_CARD | BANK_TRANSFER | …).
enum ArPaymentMethod {
  cash,
  card,
  bank;

  String get apiValue => switch (this) {
    ArPaymentMethod.cash => 'CASH',
    ArPaymentMethod.card => 'CREDIT_CARD',
    ArPaymentMethod.bank => 'BANK_TRANSFER',
  };
}

/// Salary vs advance — selects which endpoint the salary screen posts to.
enum SalaryPaymentType { salary, advance }
