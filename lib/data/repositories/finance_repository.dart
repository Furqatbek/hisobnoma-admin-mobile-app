import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/data/models/finance/finance_models.dart';

/// Repository for the finance/HR mobile features: expenses, AR (debtor)
/// payments, and employee salary/advance payments.
///
/// Contracts are proposed in docs/finance/BACKEND_HANDOFF.md. This is the only
/// layer that knows the wire shapes — if the backend uses different field names
/// or paths, change them here and nowhere else.
class FinanceRepository {
  final ApiClient _apiClient;

  FinanceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ---------------------------------------------------------------- Expenses

  /// Record an expense (cash or bank outflow).
  Future<void> createExpense({
    required double amount,
    required String description,
    required String expenseDate,
    required PaymentSource paymentSource,
    int? categoryId,
    String? category,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.expenses,
      data: {
        'amount': amount,
        'description': description,
        'expenseDate': expenseDate,
        'paymentSource': paymentSource.apiValue,
        if (categoryId != null) 'categoryId': categoryId,
        if (category != null && category.isNotEmpty) 'category': category,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  /// Optional expense categories for the dropdown. Returns an empty list if the
  /// endpoint isn't available (the screen then uses a free-text category).
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.expenseCategories);
      final list = response.data['data'] as List? ?? [];
      return list
          .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ------------------------------------------------------------- AR payments

  /// Record a payment received from a debtor (reduces their AR balance).
  /// [invoiceId] optionally targets one invoice; otherwise the backend
  /// auto-allocates oldest-first.
  Future<void> recordArPayment({
    required int customerId,
    required double amount,
    required ArPaymentMethod method,
    required String paymentDate,
    int? invoiceId,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.arPayments,
      data: {
        'customerId': customerId,
        'amount': amount,
        'paymentMethod': method.apiValue,
        'paymentDate': paymentDate,
        if (invoiceId != null) 'invoiceId': invoiceId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  // ------------------------------------------------------------------ Salary

  /// List employees for the salary/advance payee picker.
  Future<List<Employee>> getEmployees() async {
    final response = await _apiClient.get(ApiEndpoints.employees);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Record a salary or advance payment to an employee.
  Future<void> recordSalaryPayment({
    required int employeeId,
    required double amount,
    required SalaryPaymentType type,
    required String paymentDate,
    required PaymentSource paymentSource,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.salaryPayments,
      data: {
        'employeeId': employeeId,
        'amount': amount,
        'paymentType': type.apiValue,
        'paymentDate': paymentDate,
        'paymentSource': paymentSource.apiValue,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }
}
