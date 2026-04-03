// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class SUz extends S {
  SUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'Ҳисобнома';

  @override
  String get home => 'Бош саҳифа';

  @override
  String get transactions => 'Транзакциялар';

  @override
  String get reports => 'Ҳисоботлар';

  @override
  String get settings => 'Созламалар';

  @override
  String get login => 'Кириш';

  @override
  String get logout => 'Чиқиш';

  @override
  String get selectAccount => 'Ҳисобни танланг';

  @override
  String get enterPin => 'PIN кодни киритинг';

  @override
  String get pleaseEnterPin => 'Илтимос, PIN кодингизни киритинг';

  @override
  String get financialTrackingTagline => 'Молиявий бошқарув осонлашди';

  @override
  String get currentBalance => 'Жорий баланс';

  @override
  String get revenue => 'Даромад';

  @override
  String get expenses => 'Харажатлар';

  @override
  String get inventoryOverview => 'Инвентар кўриниши';

  @override
  String get financialOverview => 'Молиявий кўриниш';

  @override
  String get goodMorning => 'Хайрли тонг';

  @override
  String get goodAfternoon => 'Хайрли кун';

  @override
  String get goodEvening => 'Хайрли кеч';

  @override
  String get unableToLoadDashboard => 'Бош саҳифани юклаб бўлмади';

  @override
  String couldNotLoad(String sections) {
    return 'Юклаб бўлмади: $sections';
  }

  @override
  String get thisMonth => 'бу ой';

  @override
  String get today => 'Бугун';

  @override
  String get thisWeek => 'Бу ҳафта';

  @override
  String get revenueTrend => 'Даромад тренди';

  @override
  String get day => 'Кун';

  @override
  String get week => 'Ҳафта';

  @override
  String get month => 'Ой';

  @override
  String get year => 'Йил';

  @override
  String get noChartData => 'Диаграмма маълумотлари мавжуд эмас';

  @override
  String get avgTransaction => 'Ўрт. транзакция';

  @override
  String get activeSkus => 'Фаол SKU';

  @override
  String get lowStock => 'Кам қолган';

  @override
  String get outOfStock => 'Тугаган';

  @override
  String get totalValue => 'Умумий қиймат';

  @override
  String get expiringSoon => 'Муддати тугаяпти';

  @override
  String get totalSkus => 'Жами SKU';

  @override
  String get netCashPosition => 'Соф пул ҳолати';

  @override
  String get bankBalance => 'Банк баланси';

  @override
  String get cashBalance => 'Нақд пул баланси';

  @override
  String get receivableAr => 'Олинадиган қарз';

  @override
  String get payableAp => 'Тўланадиган қарз';

  @override
  String txnCount(String count) {
    return '$count транз.';
  }

  @override
  String get addTransaction => 'Транзакция қўшиш';

  @override
  String get income => 'Кирим';

  @override
  String get expense => 'Чиқим';

  @override
  String get all => 'Ҳаммаси';

  @override
  String get amount => 'Миқдор';

  @override
  String get notes => 'Изоҳлар';

  @override
  String get save => 'Сақлаш';

  @override
  String get cancel => 'Бекор қилиш';

  @override
  String get searchProducts => 'Маҳсулотларни қидириш';

  @override
  String get searchProductsHint => 'Маҳсулотларни қидириш...';

  @override
  String get searchProductsByNameSku =>
      'Маҳсулотларни номи ёки SKU бўйича қидириш...';

  @override
  String get products => 'Маҳсулотлар';

  @override
  String get quickSale => 'Тезкор сотув';

  @override
  String get quickCount => 'Тезкор санаш';

  @override
  String get tapSearchToFind =>
      'Маҳсулотни номи, SKU ёки штрихкод бўйича қидиринг';

  @override
  String get noResults => 'Натижа йўқ';

  @override
  String noProductsFoundFor(String query) {
    return '\"$query\" бўйича маҳсулот топилмади';
  }

  @override
  String get searchForProducts =>
      'Маҳсулотни номи, SKU бўйича қидиринг ёки штрихкод сканерланг';

  @override
  String get sellingPrice => 'Сотиш нархи';

  @override
  String get costPrice => 'Таннарх';

  @override
  String get totalStock => 'Жами захира';

  @override
  String get barcode => 'Штрихкод';

  @override
  String get stockByLocation => 'Жойлашув бўйича захира';

  @override
  String availOnHand(String available, String onHand) {
    return '$available мавжуд · $onHand қўлда';
  }

  @override
  String get addToQuickSale => 'Тезкор сотувга қўшиш';

  @override
  String get saleCompleted => 'Сотув якунланди';

  @override
  String get createQuickSaleHint =>
      'Қуйидаги тугмани босиб тезкор сотув яратинг';

  @override
  String get newSale => 'Янги сотув';

  @override
  String get total => 'Жами';

  @override
  String get paid => 'Тўланди';

  @override
  String get change => 'Қайтим';

  @override
  String get status => 'Ҳолат';

  @override
  String get time => 'Вақт';

  @override
  String get quickCountHint =>
      'Маҳсулотлар бўлимидан маҳсулотни танланг, сўнг захирани сананг';

  @override
  String get systemQty => 'Тизим миқдори';

  @override
  String get countedQty => 'Саналган миқдор';

  @override
  String get variance => 'Фарқ';

  @override
  String get untracked => 'Кузатилмайди';

  @override
  String inStock(String stock) {
    return '$stock та захирада';
  }

  @override
  String cartCount(String count) {
    return 'Саватча ($count)';
  }

  @override
  String get searchToAdd => 'Қўшиш учун маҳсулотни қидиринг';

  @override
  String get noProductsFound => 'Маҳсулотлар топилмади';

  @override
  String get addMoreItems => 'Яна қўшиш';

  @override
  String get clearAll => 'Ҳаммасини тозалаш';

  @override
  String get cash => 'Нақд';

  @override
  String get card => 'Карта';

  @override
  String completeSale(String amount) {
    return 'Сотувни якунлаш · $amount';
  }

  @override
  String saleCompletedAmount(String amount) {
    return 'Сотув якунланди · $amount';
  }

  @override
  String get failedToCompleteSale => 'Сотувни якунлаб бўлмади';

  @override
  String get revenueOverview => 'Даромад кўриниши';

  @override
  String get incomeVsExpense => 'Кирим ва Чиқим';

  @override
  String get categoryBreakdown => 'Тоифалар бўйича';

  @override
  String get unableToLoadReports => 'Ҳисоботларни юклаб бўлмади';

  @override
  String get thisMonthLabel => 'Бу ой';

  @override
  String get transactionStats => 'Транзакция статистикаси';

  @override
  String get averageTransaction => 'Ўртача транзакция';

  @override
  String get periodComparison => 'Давр солиштирмаси';

  @override
  String get todayVsYesterday => 'Бугун ва Кеча';

  @override
  String get thisWeekVsLast => 'Бу ҳафта ва Ўтган';

  @override
  String get thisMonthVsLast => 'Бу ой ва Ўтган';

  @override
  String get yesterday => 'Кеча';

  @override
  String get appearance => 'Кўриниш';

  @override
  String get darkMode => 'Қоронғу режим';

  @override
  String get themeSystem => 'Тизим';

  @override
  String get themeLight => 'Ёруғ';

  @override
  String get themeDark => 'Қоронғу';

  @override
  String get currency => 'Валюта';

  @override
  String get selectCurrency => 'Валютани танланг';

  @override
  String get data => 'Маълумотлар';

  @override
  String get syncData => 'Маълумотларни синхронлаш';

  @override
  String get clearCache => 'Кешни тозалаш';

  @override
  String get clearCacheConfirm =>
      'Кешланган маълумотлар ўчирилади. Қайта синхронлаш керак бўлиши мумкин.';

  @override
  String get clear => 'Тозалаш';

  @override
  String get cacheCleared => 'Кеш тозаланди';

  @override
  String get notifications => 'Билдиришномалар';

  @override
  String get alertPreferences => 'Огоҳлантириш созламалари';

  @override
  String get devices => 'Қурилмалар';

  @override
  String get account => 'Ҳисоб';

  @override
  String get logoutConfirm => 'Ростдан ҳам чиқмоқчимисиз?';

  @override
  String get appVersion => 'Ҳисобнома v1.0.0';

  @override
  String get language => 'Тил';

  @override
  String get selectLanguage => 'Тилни танланг';

  @override
  String get languageEn => 'English';

  @override
  String get languageUz => 'Ўзбекча';

  @override
  String get languageRu => 'Русский';

  @override
  String get dataSync => 'Маълумотларни синхронлаш';

  @override
  String get syncDescription =>
      'Маҳсулотлар, мижозлар ва тоифаларни сервердан оффлайн ишлатиш учун синхронланг.';

  @override
  String get syncNow => 'Синхронлаш';

  @override
  String get syncing => 'Синхронланмоқда...';

  @override
  String itemsSynced(String count) {
    return '$count та синхронланди';
  }

  @override
  String pendingOfflineActions(String count) {
    return '$count та кутилаётган оффлайн амал(лар)';
  }

  @override
  String get currencyUzs => 'Ўзбекистон сўми';

  @override
  String get currencyUsd => 'АҚШ доллари';

  @override
  String get currencyEur => 'Евро';

  @override
  String get currencyRub => 'Россия рубли';

  @override
  String get alerts => 'Огоҳлантиришлар';

  @override
  String get markAllRead => 'Ҳаммасини ўқилган деб белгилаш';

  @override
  String get noAlerts => 'Огоҳлантиришлар йўқ';

  @override
  String get unread => 'Ўқилмаган';

  @override
  String get allCaughtUp => 'Ҳаммаси ўқилган!';

  @override
  String get noAlertsToShow => 'Кўрсатиладиган огоҳлантириш йўқ';

  @override
  String get alertLowStock => 'Кам қолган';

  @override
  String get alertOutOfStock => 'Тугаган';

  @override
  String get alertExpiring => 'Муддати тугаяпти';

  @override
  String get alertTransaction => 'Транзакция';

  @override
  String get alertSummary => 'Хулоса';

  @override
  String get alertPriceChange => 'Нарх ўзгариши';

  @override
  String get alertNewOrder => 'Янги буюртма';

  @override
  String get alertPayment => 'Тўлов';

  @override
  String get alertPaymentDue => 'Тўлов муддати';

  @override
  String get alertOverdue => 'Муддати ўтган';

  @override
  String get alertSystem => 'Тизим';

  @override
  String get priorityLow => 'Паст';

  @override
  String get priorityNormal => 'Одатий';

  @override
  String get priorityHigh => 'Юқори';

  @override
  String get priorityUrgent => 'Шошилинч';

  @override
  String get customers => 'Мижозлар';

  @override
  String get categories => 'Тоифалар';

  @override
  String get loading => 'Юкланмоқда...';

  @override
  String get retry => 'Қайта уриниш';

  @override
  String get error => 'Хатолик';

  @override
  String get noData => 'Маълумот мавжуд эмас';
}
