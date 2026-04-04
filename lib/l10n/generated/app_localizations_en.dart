// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hisobnoma';

  @override
  String get home => 'Home';

  @override
  String get transactions => 'Transactions';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get login => 'Log In';

  @override
  String get logout => 'Log Out';

  @override
  String get selectAccount => 'Select Account';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get pleaseEnterPin => 'Please enter your PIN';

  @override
  String get financialTrackingTagline => 'Financial tracking made simple';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get revenue => 'Revenue';

  @override
  String get expenses => 'Expenses';

  @override
  String get inventoryOverview => 'Inventory Overview';

  @override
  String get financialOverview => 'Financial Overview';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get unableToLoadDashboard => 'Unable to load dashboard';

  @override
  String couldNotLoad(String sections) {
    return 'Could not load: $sections';
  }

  @override
  String get thisMonth => 'this month';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get revenueTrend => 'Revenue Trend';

  @override
  String get day => 'Day';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get noChartData => 'No chart data available';

  @override
  String get avgTransaction => 'Avg. Transaction';

  @override
  String get activeSkus => 'Active SKUs';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get totalValue => 'Total Value';

  @override
  String get expiringSoon => 'Expiring Soon';

  @override
  String get totalSkus => 'Total SKUs';

  @override
  String get netCashPosition => 'Net Cash Position';

  @override
  String get bankBalance => 'Bank Balance';

  @override
  String get cashBalance => 'Cash Balance';

  @override
  String get receivableAr => 'Receivable (AR)';

  @override
  String get payableAp => 'Payable (AP)';

  @override
  String txnCount(String count) {
    return '$count txn';
  }

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get all => 'All';

  @override
  String get amount => 'Amount';

  @override
  String get notes => 'Notes';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get searchProducts => 'Search Products';

  @override
  String get searchProductsHint => 'Search products...';

  @override
  String get searchProductsByNameSku => 'Search products by name or SKU...';

  @override
  String get products => 'Products';

  @override
  String get quickSale => 'Quick Sale';

  @override
  String get quickCount => 'Quick Count';

  @override
  String get tapSearchToFind =>
      'Tap the search icon to find products by name, SKU, or barcode';

  @override
  String get noResults => 'No results';

  @override
  String noProductsFoundFor(String query) {
    return 'No products found for \"$query\"';
  }

  @override
  String get searchForProducts =>
      'Search for products by name, SKU, or scan a barcode';

  @override
  String get sellingPrice => 'Selling Price';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get totalStock => 'Total Stock';

  @override
  String get barcode => 'Barcode';

  @override
  String get stockByLocation => 'Stock by Location';

  @override
  String availOnHand(String available, String onHand) {
    return '$available avail · $onHand on hand';
  }

  @override
  String get addToQuickSale => 'Add to Quick Sale';

  @override
  String get saleCompleted => 'Sale Completed!';

  @override
  String get createQuickSaleHint =>
      'Create a quick sale by tapping the button below';

  @override
  String get newSale => 'New Sale';

  @override
  String get total => 'Total';

  @override
  String get paid => 'Paid';

  @override
  String get change => 'Change';

  @override
  String get status => 'Status';

  @override
  String get time => 'Time';

  @override
  String get quickCountHint =>
      'Search for a product in the Products tab, then perform a stock count';

  @override
  String get systemQty => 'System Qty';

  @override
  String get countedQty => 'Counted Qty';

  @override
  String get variance => 'Variance';

  @override
  String get untracked => 'Untracked';

  @override
  String inStock(String stock) {
    return '$stock in stock';
  }

  @override
  String cartCount(String count) {
    return 'Cart ($count)';
  }

  @override
  String get searchToAdd => 'Search for a product to add';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get addMoreItems => 'Add more items';

  @override
  String get clearAll => 'Clear all';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String completeSale(String amount) {
    return 'Complete Sale · $amount';
  }

  @override
  String saleCompletedAmount(String amount) {
    return 'Sale completed · $amount';
  }

  @override
  String get failedToCompleteSale => 'Failed to complete sale';

  @override
  String productsFound(String count) {
    return '$count products found';
  }

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get profitMargin => 'Profit Margin';

  @override
  String get swipeToRemove => 'Swipe to remove';

  @override
  String get revenueOverview => 'Revenue Overview';

  @override
  String get incomeVsExpense => 'Income vs Expense';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get unableToLoadReports => 'Unable to load reports';

  @override
  String get thisMonthLabel => 'This Month';

  @override
  String get transactionStats => 'Transaction Stats';

  @override
  String get averageTransaction => 'Average Transaction';

  @override
  String get periodComparison => 'Period Comparison';

  @override
  String get todayVsYesterday => 'Today vs Yesterday';

  @override
  String get thisWeekVsLast => 'This Week vs Last';

  @override
  String get thisMonthVsLast => 'This Month vs Last';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get monthlyRevenue => 'Monthly Revenue';

  @override
  String get vsLastMonth => 'vs last month';

  @override
  String get cashFlow => 'Cash Flow';

  @override
  String get inflows => 'Inflows';

  @override
  String get outflows => 'Outflows';

  @override
  String get inventoryReport => 'Inventory Report';

  @override
  String get stockHealth => 'Stock Health';

  @override
  String get healthy => 'Healthy';

  @override
  String get inventoryValue => 'Inventory Value';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get currency => 'Currency';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get data => 'Data';

  @override
  String get syncData => 'Sync Data';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheConfirm =>
      'This will remove cached data. You may need to sync again.';

  @override
  String get clear => 'Clear';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get notifications => 'Notifications';

  @override
  String get alertPreferences => 'Alert Preferences';

  @override
  String get devices => 'Devices';

  @override
  String get account => 'Account';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get appVersion => 'Hisobnoma v1.0.0';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageEn => 'English';

  @override
  String get languageUz => 'Ўзбекча';

  @override
  String get languageRu => 'Русский';

  @override
  String get dataSync => 'Data Sync';

  @override
  String get syncDescription =>
      'Sync products, customers, and categories from the server for offline use.';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncing => 'Syncing...';

  @override
  String itemsSynced(String count) {
    return '$count items synced';
  }

  @override
  String pendingOfflineActions(String count) {
    return '$count pending offline action(s)';
  }

  @override
  String get currencyUzs => 'Uzbekistani So\'m';

  @override
  String get currencyUsd => 'US Dollar';

  @override
  String get currencyEur => 'Euro';

  @override
  String get currencyRub => 'Russian Ruble';

  @override
  String get alerts => 'Alerts';

  @override
  String get markAllRead => 'Mark All Read';

  @override
  String get noAlerts => 'No alerts';

  @override
  String get unread => 'Unread';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get noAlertsToShow => 'No alerts to show';

  @override
  String get alertLowStock => 'Low Stock';

  @override
  String get alertOutOfStock => 'Out of Stock';

  @override
  String get alertExpiring => 'Expiring';

  @override
  String get alertTransaction => 'Transaction';

  @override
  String get alertSummary => 'Summary';

  @override
  String get alertPriceChange => 'Price Change';

  @override
  String get alertNewOrder => 'New Order';

  @override
  String get alertPayment => 'Payment';

  @override
  String get alertPaymentDue => 'Payment Due';

  @override
  String get alertOverdue => 'Overdue';

  @override
  String get alertSystem => 'System';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get customers => 'Customers';

  @override
  String get categories => 'Categories';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get checkConnection =>
      'Please check your internet connection and try again';

  @override
  String get sessionExpired => 'Session expired';

  @override
  String get pleaseLoginAgain => 'Please log in again';

  @override
  String get success => 'Success';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sort by';

  @override
  String get date => 'Date';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get quantity => 'Quantity';

  @override
  String get price => 'Price';

  @override
  String get description => 'Description';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get address => 'Address';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Error';

  @override
  String get noData => 'No data available';
}
