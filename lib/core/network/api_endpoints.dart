/// All API endpoint paths for the Mobile Module
abstract final class ApiEndpoints {
  static const String baseUrl = '/api/v1/mobile';

  // Auth
  static const String login = '/auth/pin-login';
  static const String refreshToken = '/auth/refresh';
  static const String registerDevice = '/auth/register-device';
  static const String devices = '/auth/devices';
  static String deactivateDevice(String deviceId) => '/auth/devices/$deviceId';
  static const String logout = '/auth/logout';

  // Dashboard
  static const String revenueSummary = '/dashboard/revenue';
  static const String revenueChart = '/dashboard/revenue/chart';
  static const String inventorySummary = '/dashboard/inventory';
  static const String financialSummary = '/dashboard/financial';

  // Alerts
  static const String alerts = '/alerts';
  static const String unreadCount = '/alerts/unread-count';
  static String markRead(int id) => '/alerts/$id/read';
  static const String markAllRead = '/alerts/read-all';
  static const String alertPreferences = '/alerts/preferences';
  static String updateAlertPreference(String alertType) =>
      '/alerts/preferences/$alertType';

  // Quick Actions
  static String barcodeLookup(String barcode) => '/barcode/$barcode';
  static const String quickCount = '/quick-count';
  static const String quickSale = '/quick-sale';
  static const String searchProducts = '/products/search';
  static const String searchCustomers = '/customers/search';

  // Sync
  static const String syncProducts = '/sync/products';
  static const String syncCustomers = '/sync/customers';
  static const String syncCategories = '/sync/categories';
  static const String syncLastUpdated = '/sync/last-updated';
}
