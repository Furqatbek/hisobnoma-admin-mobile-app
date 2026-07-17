import 'package:hisobnoma/core/router/app_router.dart';

/// Routes this app actually has. A notification payload's `route` is only
/// honored if it matches one of these — the backend may send deep links for
/// detail screens that don't exist yet, and navigating to an unknown route
/// would show a GoRouter error page.
const Set<String> kKnownNotificationRoutes = <String>{
  AppRoutes.home,
  AppRoutes.transactions,
  AppRoutes.reports,
  AppRoutes.settings,
  AppRoutes.alerts,
};

/// Resolve a notification `data` payload to an in-app route.
///
/// Precedence:
/// 1. An explicit `route` that the app actually has → use it.
/// 2. Otherwise map by `type` (transaction-ish types → Transactions).
/// 3. Fall back to the Alerts center, where the alert's content lives.
///
/// Pure and side-effect free so it can be unit-tested; [HisobnomaApp] passes
/// the result to `GoRouter.go`.
String resolveNotificationRoute(Map<String, dynamic> data) {
  final route = data['route'];
  if (route is String && kKnownNotificationRoutes.contains(route)) {
    return route;
  }

  switch (data['type']) {
    case 'new_order':
    case 'large_transaction':
      return AppRoutes.transactions;
    default:
      return AppRoutes.alerts;
  }
}
