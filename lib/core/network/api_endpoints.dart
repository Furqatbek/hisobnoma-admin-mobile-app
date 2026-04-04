/// All API endpoint paths for the Mobile Module
abstract final class ApiEndpoints {
  static const String baseUrl = '/api/v1';

  // Auth
  static const String usersList = '/auth/users/list';
  static const String login = '/auth/pin-login';
  static const String refreshToken = '/auth/refresh';
  static const String registerDevice = '/auth/register-device';
  static const String devices = '/auth/devices';
  static String deactivateDevice(String deviceId) => '/auth/devices/$deviceId';
  static const String logout = '/auth/logout';

  // Dashboard
  static const String revenueSummary = '/mobile/dashboard/revenue';
  static const String revenueChart = '/mobile/dashboard/revenue/chart';
  static const String inventorySummary = '/mobile/dashboard/inventory';
  static const String financialSummary = '/mobile/dashboard/finance';

  // Alerts
  static const String alerts = '/mobile/alerts';
  static const String unreadCount = '/mobile/alerts/count';
  static String markRead(int id) => '/mobile/alerts/$id/read';
  static const String markAllRead = '/mobile/alerts/read-all';
  static const String alertPreferences = '/mobile/alerts/preferences';
  static String updateAlertPreference(String alertType) =>
      '/mobile/alerts/preferences/$alertType';

  // Quick Actions
  static String barcodeLookup(String barcode) => '/mobile/barcode/$barcode';
  static const String quickCount = '/mobile/quick-count';
  static const String quickSale = '/mobile/pos/quick-sale';
  static const String searchProducts = '/mobile/products/search';
  static const String searchCustomers = '/mobile/customers/search';

  // Inventory
  static const String inventoryProducts = '/inventory/products';

  // Finance / AR
  static const String arCustomerBalance =
      '/finance/ar-reports/customer-balance';

  // Sales history
  static const String posTransactions = '/pos/transactions';
  static String posTransactionDetail(int id) => '/pos/transactions/$id';

  // Sync
  static const String syncProducts = '/mobile/sync/products';
  static const String syncCustomers = '/mobile/sync/customers';
  static const String syncCategories = '/mobile/sync/categories';
  static const String syncLastUpdated = '/mobile/sync/last-updated';
}
