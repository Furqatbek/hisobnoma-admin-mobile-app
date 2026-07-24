/// Models for the finance/HR mobile features (expenses, AR payments,
/// salary/advance). See docs/finance/BACKEND_HANDOFF.md for the contracts.

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

/// A simple expense category, for the optional dropdown.
class ExpenseCategory {
  final int id;
  final String name;

  const ExpenseCategory({required this.id, required this.name});

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
    );
  }
}

/// Cash vs bank source for an outflow (expense / salary).
enum PaymentSource {
  cash,
  bank;

  String get apiValue => this == PaymentSource.cash ? 'CASH' : 'BANK';
}

/// Method for an incoming AR payment.
enum ArPaymentMethod {
  cash,
  card,
  bank;

  String get apiValue => switch (this) {
    ArPaymentMethod.cash => 'CASH',
    ArPaymentMethod.card => 'CARD',
    ArPaymentMethod.bank => 'BANK',
  };
}

/// Salary vs advance.
enum SalaryPaymentType {
  salary,
  advance;

  String get apiValue =>
      this == SalaryPaymentType.salary ? 'SALARY' : 'ADVANCE';
}
