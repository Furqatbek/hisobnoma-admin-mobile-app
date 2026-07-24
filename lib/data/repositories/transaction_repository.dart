import 'package:dio/dio.dart';
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

  /// Barcode product lookup. Uses the documented path, falling back to the
  /// pre-doc path if the backend returns 404 (endpoint not yet deployed).
  Future<ProductLookup> barcodeLookup(String barcode) async {
    final response = await _getWithFallback(
      ApiEndpoints.barcodeLookup(barcode),
      ApiEndpoints.barcodeLookupLegacy(barcode),
    );
    return ProductLookup.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Quick stock count. Documented path with a 404 fallback to the pre-doc
  /// path. A 404 means nothing was recorded server-side, so retrying the
  /// fallback can't double-count.
  Future<QuickCountResponse> quickCount(QuickCountRequest request) async {
    final response = await _postWithFallback(
      ApiEndpoints.quickCount,
      ApiEndpoints.quickCountLegacy,
      request.toJson(),
    );
    return QuickCountResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// GET [primary]; if it 404s (path not deployed), retry [fallback].
  Future<Response> _getWithFallback(String primary, String fallback) async {
    try {
      return await _apiClient.get(primary);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return await _apiClient.get(fallback);
      }
      rethrow;
    }
  }

  /// POST [data] to [primary]; if it 404s, retry [fallback]. Safe only when a
  /// 404 guarantees no server-side effect (true for an unmatched route).
  Future<Response> _postWithFallback(
    String primary,
    String fallback,
    dynamic data,
  ) async {
    try {
      return await _apiClient.post(primary, data: data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return await _apiClient.post(fallback, data: data);
      }
      rethrow;
    }
  }

  /// Quick sale. Safe to auto-retry ONLY when the request carries a
  /// clientRequestId (idempotency key) — the backend dedups on it, so a
  /// retried sale returns the original transaction instead of a duplicate.
  Future<QuickSaleResponse> quickSale(QuickSaleRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.quickSale,
      data: request.toJson(),
      options: request.clientRequestId != null
          ? Options(extra: {'idempotent': true})
          : null,
    );
    return QuickSaleResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
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

  /// Server-side product search (paginated). The enriched /mobile/products
  /// /search now returns the same fields as /inventory/products, so results
  /// parse into InventoryProduct and drop into the cart identically to listed
  /// products. Reaches items beyond the initial page (fixes H13/H14).
  Future<PaginatedResponse<InventoryProduct>> searchInventoryProducts({
    required String query,
    int page = 0,
    int size = 30,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.searchProducts,
      queryParameters: {'query': query, 'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      InventoryProduct.fromJson,
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
    final response = await _apiClient.get(ApiEndpoints.arCustomerBalance);
    return CustomerBalanceReport.fromJson(
      response.data as Map<String, dynamic>,
    );
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
    return SaleDetail.fromJson(response.data['data'] as Map<String, dynamic>);
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
      if (data is Map<String, dynamic>) {
        if (data.containsKey('id')) return Shift.fromJson(data);
        final nested = data['data'];
        if (nested is Map<String, dynamic>) return Shift.fromJson(nested);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get the open shift for a specific terminal.
  ///
  /// The backend has no terminal-scoped current-shift endpoint, so we fetch all
  /// open shifts for the tenant (`GET /mobile/shifts/open`) and pick the one on
  /// this terminal.
  Future<Shift?> getCurrentShiftForTerminal(int terminalId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.openShifts);
      final shifts = _parseShiftList(response.data);
      for (final shift in shifts) {
        if (shift.terminalId == terminalId) return shift;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parse a list of shifts from either a raw array or an ApiResponse-wrapped
  /// `{ "data": [...] }` payload.
  List<Shift> _parseShiftList(dynamic data) {
    final List raw;
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      raw = data['data'] as List;
    } else {
      return const [];
    }
    return raw.whereType<Map<String, dynamic>>().map(Shift.fromJson).toList();
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
      // Direct shift object: { "id": 42, "shiftNumber": "...", ... }
      if (data.containsKey('id')) {
        return Shift.fromJson(data);
      }
      // Wrapped: { "success": true, "data": { ...shift } }
      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        return Shift.fromJson(nested);
      }
    }
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
