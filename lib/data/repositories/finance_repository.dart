import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/data/models/finance/finance_models.dart';

/// Repository for the finance/HR mobile features: expenses, debtor (AR)
/// payments, and employee salary/advance payments.
///
/// Wire shapes follow docs/api/MOBILE_MODULE_API.md. This is the only layer
/// that knows the field names/paths — change them here and nowhere else.
class FinanceRepository {
  final ApiClient _apiClient;

  FinanceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ---------------------------------------------------------------- Expenses

  /// Record an expense. Backend fields: totalAmount (required), category
  /// (optional, defaults to "Boshqa"), createDate, currency, notes.
  Future<void> createExpense({
    required double totalAmount,
    required String createDate,
    String? category,
    String currency = 'UZS',
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.expenses,
      data: {
        'totalAmount': totalAmount,
        'createDate': createDate,
        'currency': currency,
        if (category != null && category.isNotEmpty) 'category': category,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  // -------------------------------------------------------- Debtor payments

  /// Record a payment received from a debtor (reduces their AR balance).
  /// [invoiceId] optionally targets one invoice; otherwise the backend
  /// auto-allocates oldest-due-first. Overpayment is kept as credit. There is
  /// no date field on this endpoint.
  Future<void> recordDebtorPayment({
    required int customerId,
    required double amount,
    required ArPaymentMethod method,
    int? invoiceId,
    String? referenceNumber,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.debtorPayment,
      data: {
        'customerId': customerId,
        'amount': amount,
        'paymentMethod': method.apiValue,
        if (invoiceId != null) 'invoiceId': invoiceId,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  // ------------------------------------------------------------------ Salary

  /// List employees for the salary/advance payee picker. Not documented in the
  /// mobile module doc — assumed to exist in the HR module (like /pos/terminals).
  Future<List<Employee>> getEmployees() async {
    final response = await _apiClient.get(ApiEndpoints.employees);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Record & pay a salary for a period. Salary uses baseAmount (+ optional
  /// bonus/deduction) and a period year/month — no date, no cash/bank source.
  Future<void> recordSalary({
    required int employeeId,
    required int periodYear,
    required int periodMonth,
    required double baseAmount,
    double bonusAmount = 0,
    double deductionAmount = 0,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.salaryPayment,
      data: {
        'employeeId': employeeId,
        'periodYear': periodYear,
        'periodMonth': periodMonth,
        'baseAmount': baseAmount,
        'bonusAmount': bonusAmount,
        'deductionAmount': deductionAmount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  /// Record a paid advance against a period. Uses a flat amount + advanceDate.
  Future<void> recordAdvance({
    required int employeeId,
    required double amount,
    required int periodYear,
    required int periodMonth,
    required String advanceDate,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.advancePayment,
      data: {
        'employeeId': employeeId,
        'amount': amount,
        'periodYear': periodYear,
        'periodMonth': periodMonth,
        'advanceDate': advanceDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }
}
