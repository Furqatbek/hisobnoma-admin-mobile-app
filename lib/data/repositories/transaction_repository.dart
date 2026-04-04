import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/core/network/api_response.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';

/// Repository for transaction / quick action operations
class TransactionRepository {
  final ApiClient _apiClient;

  TransactionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

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

  /// Search customers (paginated)
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
}
