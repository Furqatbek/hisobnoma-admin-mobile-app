import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/core/network/api_response.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';

/// Repository for transaction / quick action operations
class TransactionRepository {
  final ApiClient _apiClient;

  TransactionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Get active POS terminals
  Future<List<PosTerminal>> getActiveTerminals() async {
    final response = await _apiClient.get(ApiEndpoints.activeTerminals);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => PosTerminal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get active products (paginated)
  Future<PaginatedResponse<ProductLookup>> getActiveProducts({
    int page = 0,
    int size = 50,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.activeProducts,
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data as Map<String, dynamic>;
    return PaginatedResponse.fromJson(data, ProductLookup.fromJson);
  }

  /// Get active delivery regions
  Future<List<DeliveryRegion>> getDeliveryRegions() async {
    final response = await _apiClient.get(ApiEndpoints.deliveryRegions);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => DeliveryRegion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get villages/areas for a delivery region
  Future<List<DeliveryVillage>> getDeliveryVillages(int regionId) async {
    final response = await _apiClient.get(
      ApiEndpoints.deliveryVillages(regionId),
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => DeliveryVillage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Barcode product lookup
  Future<ProductLookup> barcodeLookup(String barcode) async {
    final response = await _apiClient.get(
      ApiEndpoints.barcodeLookup(barcode),
    );
    return ProductLookup.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Quick stock count
  Future<QuickCountResponse> quickCount(QuickCountRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.quickCount,
      data: request.toJson(),
    );
    return QuickCountResponse.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Quick sale
  Future<QuickSaleResponse> quickSale(QuickSaleRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.quickSale,
      data: request.toJson(),
    );
    return QuickSaleResponse.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Search products (paginated)
  Future<PaginatedResponse<ProductLookup>> searchProducts({
    required String query,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.searchProducts,
      queryParameters: {'query': query, 'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      ProductLookup.fromJson,
    );
  }

  /// Get inventory products (paginated)
  Future<List<InventoryProduct>> getInventoryProducts({
    int page = 0,
    int size = 100,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.inventoryProducts,
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['content'] as List)
        .map((e) => InventoryProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get customer balance report (debtors)
  Future<CustomerBalanceReport> getCustomerBalances() async {
    final response = await _apiClient.get(
      ApiEndpoints.arCustomerBalance,
    );
    return CustomerBalanceReport.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Get POS transactions (paginated, optionally filtered by date)
  Future<List<SaleRecord>> getTransactions({
    int page = 0,
    int size = 50,
    String? date,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.posTransactions,
      queryParameters: {
        'page': page,
        'size': size,
        if (date != null) 'date': date,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (data['content'] as List)
        .map((e) => SaleRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get unpaid invoices for a customer
  Future<List<UnpaidInvoice>> getCustomerUnpaidInvoices(int customerId) async {
    final response = await _apiClient.get(
      ApiEndpoints.arCustomerUnpaid(customerId),
    );
    final list = response.data as List? ?? [];
    return list
        .map((e) => UnpaidInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get transaction detail by ID
  Future<SaleDetail> getTransactionDetail(int id) async {
    final response = await _apiClient.get(
      ApiEndpoints.posTransactionDetail(id),
    );
    return SaleDetail.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Search customers (paginated) via mobile endpoint
  Future<PaginatedResponse<Map<String, dynamic>>> searchCustomers({
    required String query,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.searchCustomers,
      queryParameters: {'query': query, 'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      (json) => json,
    );
  }

  /// Fetch all finance customers (for client selection in debt sale)
  Future<List<Map<String, dynamic>>> getFinanceCustomers({
    int size = 1000,
    String sort = 'name,asc',
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.financeCustomers,
      queryParameters: {'size': size, 'sort': sort},
    );
    final data = response.data as Map<String, dynamic>;
    final content = data['content'] as List? ?? [];
    return content.cast<Map<String, dynamic>>();
  }

  /// Create a new finance customer
  Future<Map<String, dynamic>> createFinanceCustomer({
    required String name,
    String? phone,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.financeCustomers,
      data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ========== Shifts ==========

  /// Get current shift for the logged-in user
  Future<Shift?> getCurrentShift() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.currentShift);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Shift.fromJson(data['data'] as Map<String, dynamic>);
      }
      if (data is Map<String, dynamic> && data['id'] != null) {
        return Shift.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get current shift for a specific terminal
  Future<Shift?> getCurrentShiftForTerminal(int terminalId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.currentShiftForTerminal(terminalId),
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Shift.fromJson(data['data'] as Map<String, dynamic>);
      }
      if (data is Map<String, dynamic> && data['id'] != null) {
        return Shift.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Open a new shift
  Future<Shift> openShift({
    required int terminalId,
    required double openingCash,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.openShift,
      data: {
        'terminalId': terminalId,
        'openingCash': openingCash,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return _parseShiftResponse(response.data);
  }

  /// Close a shift
  Future<Shift> closeShift({
    required int shiftId,
    required double closingCash,
    String? closingNotes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.closeShift(shiftId),
      data: {
        'closingCash': closingCash,
        if (closingNotes != null && closingNotes.isNotEmpty)
          'closingNotes': closingNotes,
      },
    );
    return _parseShiftResponse(response.data);
  }

  Shift _parseShiftResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      // { "success": true, "data": { ...shift } }
      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        return Shift.fromJson(nested);
      }
      // Response is the shift object itself
      if (data.containsKey('id')) {
        return Shift.fromJson(data);
      }
    }
    // Fallback: re-fetch current shift
    throw Exception('Unexpected shift response format');
  }

  /// Cash in/out operation on a shift
  Future<void> cashOperation({
    required int shiftId,
    required String operationType, // CASH_IN or CASH_OUT
    required double amount,
    String? reason,
  }) async {
    await _apiClient.post(
      ApiEndpoints.cashOperation(shiftId),
      data: {
        'operationType': operationType,
        'amount': amount,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }
}
