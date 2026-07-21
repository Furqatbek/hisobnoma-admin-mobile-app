import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/core/router/app_router.dart';
import 'package:hisobnoma/core/services/notification_router.dart';

void main() {
  group('resolveNotificationRoute', () {
    test('honors an explicit route the app has', () {
      expect(
        resolveNotificationRoute({'route': AppRoutes.transactions}),
        AppRoutes.transactions,
      );
      expect(
        resolveNotificationRoute({'route': AppRoutes.settings}),
        AppRoutes.settings,
      );
    });

    test('ignores an unknown deep-link route and falls back', () {
      // Backend may send detail routes this app has no screen for.
      expect(
        resolveNotificationRoute({'route': '/orders/555'}),
        AppRoutes.alerts,
      );
    });

    test('an unknown route still respects the type fallback', () {
      expect(
        resolveNotificationRoute({'route': '/orders/555', 'type': 'new_order'}),
        AppRoutes.transactions,
      );
    });

    test('maps transaction-ish types to Transactions', () {
      expect(
        resolveNotificationRoute({'type': 'new_order'}),
        AppRoutes.transactions,
      );
      expect(
        resolveNotificationRoute({'type': 'large_transaction'}),
        AppRoutes.transactions,
      );
    });

    test('falls back to Alerts for other/unknown/missing types', () {
      expect(resolveNotificationRoute({'type': 'low_stock'}), AppRoutes.alerts);
      expect(
        resolveNotificationRoute({'type': 'payment_due'}),
        AppRoutes.alerts,
      );
      expect(resolveNotificationRoute({'type': 'system'}), AppRoutes.alerts);
      expect(resolveNotificationRoute({}), AppRoutes.alerts);
    });

    test('tolerates non-string values without throwing', () {
      // id arrives as a number; route/type could be absent or wrong-typed.
      expect(
        resolveNotificationRoute({'id': 555, 'route': 42}),
        AppRoutes.alerts,
      );
    });
  });
}
