import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';

/// Repository for transaction / quick action operations
class TransactionRepository {
  final ApiClient _apiClient;

  TransactionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Barcode product lookup
  Future<Map<String, dynamic>> barcodeLookup(String barcode) async {
    final response = await _apiClient.get(
      ApiEndpoints.barcodeLookup(barcode),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Quick stock count
  Future<Map<String, dynamic>> quickCount({
    required int productId,
    required int locationId,
    required int countedQuantity,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.quickCount,
      data: {
        'productId': productId,
        'locationId': locationId,
        'countedQuantity': countedQuantity,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Quick sale
  Future<Map<String, dynamic>> quickSale({
    required int terminalId,
    int? customerId,
    required List<Map<String, dynamic>> items,
    required String paymentType,
    required double tenderedAmount,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.quickSale,
      data: {
        'terminalId': terminalId,
        'customerId': customerId,
        'items': items,
        'paymentType': paymentType,
        'tenderedAmount': tenderedAmount,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Search products
  Future<Map<String, dynamic>> searchProducts({
    required String query,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.searchProducts,
      queryParameters: {'query': query, 'page': page, 'size': size},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Search customers
  Future<Map<String, dynamic>> searchCustomers({
    required String query,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.searchCustomers,
      queryParameters: {'query': query, 'page': page, 'size': size},
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
