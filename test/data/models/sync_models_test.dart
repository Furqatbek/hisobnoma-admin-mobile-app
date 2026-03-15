import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/data/models/sync/sync_models.dart';

void main() {
  group('SyncProduct', () {
    final json = {
      'id': 1,
      'sku': 'SKU-001',
      'barcode': '1234567890',
      'name': 'Test Product',
      'categoryId': 5,
      'categoryName': 'Electronics',
      'sellingPrice': 150000.0,
      'costPrice': 100000.0,
      'unitOfMeasure': 'pcs',
      'trackInventory': true,
      'active': true,
      'updatedAt': '2026-01-15T10:30:00.000Z',
    };

    test('fromJson parses correctly', () {
      final product = SyncProduct.fromJson(json);

      expect(product.id, 1);
      expect(product.sku, 'SKU-001');
      expect(product.barcode, '1234567890');
      expect(product.name, 'Test Product');
      expect(product.categoryId, 5);
      expect(product.sellingPrice, 150000.0);
      expect(product.trackInventory, true);
      expect(product.active, true);
    });

    test('fromJson handles null optionals', () {
      final minJson = {
        'id': 2,
        'sku': 'SKU-002',
        'name': 'Min Product',
        'updatedAt': '2026-01-15T10:30:00.000Z',
      };

      final product = SyncProduct.fromJson(minJson);
      expect(product.barcode, isNull);
      expect(product.categoryId, isNull);
      expect(product.sellingPrice, 0);
      expect(product.unitOfMeasure, 'pcs');
    });

    test('toDbRow converts to database map', () {
      final product = SyncProduct.fromJson(json);
      final row = product.toDbRow();

      expect(row['id'], 1);
      expect(row['sku'], 'SKU-001');
      expect(row['category_id'], 5);
      expect(row['category_name'], 'Electronics');
      expect(row['selling_price'], 150000.0);
      expect(row['track_inventory'], 1); // bool → int
      expect(row['active'], 1);
      expect(row['updated_at'], isA<String>());
    });
  });

  group('SyncCustomer', () {
    final json = {
      'id': 10,
      'code': 'CUST-010',
      'name': 'John Doe',
      'phone': '+998901234567',
      'email': 'john@example.com',
      'priceListId': 1,
      'creditLimit': 5000000.0,
      'currentBalance': 1500000.0,
      'active': true,
      'updatedAt': '2026-02-01T08:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final customer = SyncCustomer.fromJson(json);

      expect(customer.id, 10);
      expect(customer.code, 'CUST-010');
      expect(customer.name, 'John Doe');
      expect(customer.phone, '+998901234567');
      expect(customer.creditLimit, 5000000.0);
    });

    test('toDbRow converts to database map', () {
      final customer = SyncCustomer.fromJson(json);
      final row = customer.toDbRow();

      expect(row['id'], 10);
      expect(row['code'], 'CUST-010');
      expect(row['price_list_id'], 1);
      expect(row['credit_limit'], 5000000.0);
      expect(row['active'], 1);
    });
  });

  group('SyncCategory', () {
    final json = {
      'id': 3,
      'name': 'Electronics',
      'parentId': null,
      'sortOrder': 1,
      'active': true,
      'updatedAt': '2026-01-10T12:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final category = SyncCategory.fromJson(json);

      expect(category.id, 3);
      expect(category.name, 'Electronics');
      expect(category.parentId, isNull);
      expect(category.sortOrder, 1);
      expect(category.active, true);
    });

    test('toDbRow converts to database map', () {
      final category = SyncCategory.fromJson(json);
      final row = category.toDbRow();

      expect(row['id'], 3);
      expect(row['name'], 'Electronics');
      expect(row['parent_id'], isNull);
      expect(row['sort_order'], 1);
      expect(row['active'], 1);
    });
  });

  group('SyncResponse', () {
    test('fromJson parses with items', () {
      final json = {
        'lastSyncAt': '2026-03-15T10:00:00.000Z',
        'syncVersion': '2.0',
        'fullSyncRequired': false,
        'products': [
          {
            'id': 1,
            'sku': 'SKU-001',
            'name': 'Product 1',
            'updatedAt': '2026-03-15T10:00:00.000Z',
          },
        ],
      };

      final response = SyncResponse.fromJson(
        json,
        itemsKey: 'products',
        fromJsonT: SyncProduct.fromJson,
      );

      expect(response.lastSyncAt.year, 2026);
      expect(response.syncVersion, '2.0');
      expect(response.fullSyncRequired, false);
      expect(response.items.length, 1);
      expect(response.count, 1);
      expect(response.isEmpty, false);
    });

    test('fromJson handles empty items', () {
      final json = {
        'lastSyncAt': '2026-03-15T10:00:00.000Z',
        'products': <Map<String, dynamic>>[],
      };

      final response = SyncResponse.fromJson(
        json,
        itemsKey: 'products',
        fromJsonT: SyncProduct.fromJson,
      );

      expect(response.isEmpty, true);
      expect(response.count, 0);
    });

    test('fromJson handles missing items key', () {
      final json = {
        'lastSyncAt': '2026-03-15T10:00:00.000Z',
      };

      final response = SyncResponse.fromJson(
        json,
        itemsKey: 'products',
        fromJsonT: SyncProduct.fromJson,
      );

      expect(response.isEmpty, true);
    });
  });
}
