import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/data/models/alert/alert_models.dart';

void main() {
  group('AlertType', () {
    test('fromString parses all known types', () {
      expect(AlertType.fromString('LOW_STOCK'), AlertType.lowStock);
      expect(AlertType.fromString('OUT_OF_STOCK'), AlertType.outOfStock);
      expect(AlertType.fromString('EXPIRING_INVENTORY'),
          AlertType.expiringInventory);
      expect(AlertType.fromString('LARGE_TRANSACTION'),
          AlertType.largeTransaction);
      expect(AlertType.fromString('DAILY_SUMMARY'), AlertType.dailySummary);
      expect(AlertType.fromString('PRICE_CHANGE'), AlertType.priceChange);
      expect(AlertType.fromString('NEW_ORDER'), AlertType.newOrder);
      expect(AlertType.fromString('PAYMENT_RECEIVED'),
          AlertType.paymentReceived);
      expect(AlertType.fromString('PAYMENT_DUE'), AlertType.paymentDue);
      expect(
          AlertType.fromString('PAYMENT_OVERDUE'), AlertType.paymentOverdue);
      expect(AlertType.fromString('SYSTEM'), AlertType.system);
    });

    test('fromString returns system for unknown values', () {
      expect(AlertType.fromString('UNKNOWN'), AlertType.system);
    });

    test('apiValue returns correct string', () {
      expect(AlertType.lowStock.apiValue, 'LOW_STOCK');
      expect(AlertType.paymentReceived.apiValue, 'PAYMENT_RECEIVED');
      expect(AlertType.system.apiValue, 'SYSTEM');
    });
  });

  group('AlertPriority', () {
    test('fromString parses all priorities', () {
      expect(AlertPriority.fromString('LOW'), AlertPriority.low);
      expect(AlertPriority.fromString('NORMAL'), AlertPriority.normal);
      expect(AlertPriority.fromString('HIGH'), AlertPriority.high);
      expect(AlertPriority.fromString('URGENT'), AlertPriority.urgent);
    });

    test('fromString defaults to normal', () {
      expect(AlertPriority.fromString('UNKNOWN'), AlertPriority.normal);
    });
  });

  group('Alert', () {
    final json = {
      'id': 1,
      'alertType': 'LOW_STOCK',
      'title': 'Low Stock Alert',
      'message': 'Product XYZ is running low',
      'priority': 'HIGH',
      'entityType': 'product',
      'entityId': 42,
      'isRead': false,
      'createdAt': '2026-01-15T10:30:00.000Z',
    };

    test('fromJson parses correctly', () {
      final alert = Alert.fromJson(json);

      expect(alert.id, 1);
      expect(alert.alertType, AlertType.lowStock);
      expect(alert.title, 'Low Stock Alert');
      expect(alert.message, 'Product XYZ is running low');
      expect(alert.priority, AlertPriority.high);
      expect(alert.entityType, 'product');
      expect(alert.entityId, 42);
      expect(alert.isRead, false);
      expect(alert.createdAt.year, 2026);
    });

    test('fromJson handles null optionals', () {
      final minJson = {
        'id': 2,
        'alertType': 'SYSTEM',
        'title': 'System Alert',
        'message': 'Maintenance scheduled',
        'priority': 'LOW',
        'isRead': true,
        'createdAt': '2026-03-01T08:00:00.000Z',
      };

      final alert = Alert.fromJson(minJson);
      expect(alert.entityType, isNull);
      expect(alert.entityId, isNull);
      expect(alert.isRead, true);
    });

    test('copyWith creates new instance with updated fields', () {
      final alert = Alert.fromJson(json);
      final updated = alert.copyWith(isRead: true);

      expect(updated.isRead, true);
      expect(updated.id, alert.id);
      expect(updated.title, alert.title);
    });

    test('copyWith preserves values when no args passed', () {
      final alert = Alert.fromJson(json);
      final copy = alert.copyWith();

      expect(copy.isRead, alert.isRead);
      expect(copy.id, alert.id);
    });
  });

  group('AlertPreference', () {
    final json = {
      'id': 1,
      'alertType': 'LOW_STOCK',
      'pushEnabled': true,
      'inAppEnabled': true,
      'emailEnabled': false,
      'smsEnabled': false,
      'thresholdValue': 10,
    };

    test('fromJson parses correctly', () {
      final pref = AlertPreference.fromJson(json);

      expect(pref.id, 1);
      expect(pref.alertType, AlertType.lowStock);
      expect(pref.pushEnabled, true);
      expect(pref.inAppEnabled, true);
      expect(pref.emailEnabled, false);
      expect(pref.smsEnabled, false);
      expect(pref.thresholdValue, 10);
    });

    test('toJson produces correct map', () {
      final pref = AlertPreference.fromJson(json);
      final output = pref.toJson();

      expect(output['pushEnabled'], true);
      expect(output['emailEnabled'], false);
      expect(output['thresholdValue'], 10);
    });

    test('copyWith updates fields', () {
      final pref = AlertPreference.fromJson(json);
      final updated = pref.copyWith(pushEnabled: false, emailEnabled: true);

      expect(updated.pushEnabled, false);
      expect(updated.emailEnabled, true);
      expect(updated.inAppEnabled, true); // unchanged
    });
  });
}
