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
  String get transactions => 'Амалиётлар';

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
  String get financialTrackingTagline => 'Молиявий бошқарув — осон ва қулай';

  @override
  String get currentBalance => 'Жорий баланс';

  @override
  String get revenue => 'Тушум';

  @override
  String get expenses => 'Харажатлар';

  @override
  String get inventoryOverview => 'Омбор ҳолати';

  @override
  String get financialOverview => 'Молиявий ҳолат';

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
  String get thisMonth => 'шу ой';

  @override
  String get today => 'Бугун';

  @override
  String get thisWeek => 'Шу ҳафта';

  @override
  String get revenueTrend => 'Тушум динамикаси';

  @override
  String get day => 'Кун';

  @override
  String get week => 'Ҳафта';

  @override
  String get month => 'Ой';

  @override
  String get year => 'Йил';

  @override
  String get noChartData => 'Диаграмма учун маълумот йўқ';

  @override
  String get avgTransaction => 'Ўрт. амалиёт';

  @override
  String get activeSkus => 'Фаол товарлар';

  @override
  String get lowStock => 'Кам қолган';

  @override
  String get outOfStock => 'Тугаган';

  @override
  String get totalValue => 'Умумий қиймат';

  @override
  String get expiringSoon => 'Муддати тугамоқда';

  @override
  String get totalSkus => 'Жами товарлар';

  @override
  String get netCashPosition => 'Соф пул қолдиғи';

  @override
  String get bankBalance => 'Банк ҳисоби';

  @override
  String get cashBalance => 'Нақд пул';

  @override
  String get receivableAr => 'Олинадиган қарз';

  @override
  String get payableAp => 'Тўланадиган қарз';

  @override
  String txnCount(String count) {
    return '$count та амалиёт';
  }

  @override
  String get addTransaction => 'Амалиёт қўшиш';

  @override
  String get income => 'Кирим';

  @override
  String get expense => 'Чиқим';

  @override
  String get all => 'Ҳаммаси';

  @override
  String get amount => 'Сумма';

  @override
  String get notes => 'Изоҳ';

  @override
  String get save => 'Сақлаш';

  @override
  String get cancel => 'Бекор қилиш';

  @override
  String get searchProducts => 'Товарларни қидириш';

  @override
  String get searchProductsHint => 'Товарларни қидириш...';

  @override
  String get searchProductsByNameSku => 'Номи ёки SKU бўйича қидириш...';

  @override
  String get products => 'Товарлар';

  @override
  String get quickSale => 'Тезкор сотув';

  @override
  String get quickCount => 'Тезкор санаш';

  @override
  String get tapSearchToFind =>
      'Товарни номи, SKU ёки штрихкод бўйича қидиринг';

  @override
  String get noResults => 'Натижа топилмади';

  @override
  String noProductsFoundFor(String query) {
    return '\"$query\" бўйича товар топилмади';
  }

  @override
  String get searchForProducts =>
      'Товарни номи, SKU бўйича қидиринг ёки штрихкод сканерланг';

  @override
  String get sellingPrice => 'Сотиш нархи';

  @override
  String get costPrice => 'Таннарх';

  @override
  String get totalStock => 'Жами захира';

  @override
  String get barcode => 'Штрихкод';

  @override
  String get stockByLocation => 'Жой бўйича захира';

  @override
  String availOnHand(String available, String onHand) {
    return '$available мавжуд · $onHand қўлда';
  }

  @override
  String get addToQuickSale => 'Сотувга қўшиш';

  @override
  String get saleCompleted => 'Сотув муваффақиятли!';

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
      'Товарлар бўлимидан товарни танланг, сўнг захирани сананг';

  @override
  String get systemQty => 'Тизимдаги';

  @override
  String get countedQty => 'Ҳисобланган';

  @override
  String get variance => 'Фарқ';

  @override
  String get untracked => 'Ҳисобга олинмайди';

  @override
  String inStock(String stock) {
    return 'Захирада: $stock та';
  }

  @override
  String cartCount(String count) {
    return 'Савати ($count)';
  }

  @override
  String get searchToAdd => 'Қўшиш учун товарни қидиринг';

  @override
  String get noProductsFound => 'Товар топилмади';

  @override
  String get addMoreItems => 'Яна қўшиш';

  @override
  String get clearAll => 'Тозалаш';

  @override
  String get cash => 'Нақд';

  @override
  String get card => 'Карта';

  @override
  String completeSale(String amount) {
    return 'Сотувни тасдиқлаш · $amount';
  }

  @override
  String saleCompletedAmount(String amount) {
    return 'Сотилди · $amount';
  }

  @override
  String get failedToCompleteSale => 'Сотувда хатолик юз берди';

  @override
  String productsFound(String count) {
    return '$count та товар топилди';
  }

  @override
  String get scanBarcode => 'Штрихкод сканерлаш';

  @override
  String get profitMargin => 'Фойда маржаси';

  @override
  String get swipeToRemove => 'Ўчириш учун суринг';

  @override
  String get revenueOverview => 'Тушум кўриниши';

  @override
  String get incomeVsExpense => 'Кирим ва Чиқим';

  @override
  String get categoryBreakdown => 'Тоифалар бўйича';

  @override
  String get unableToLoadReports => 'Ҳисоботларни юклаб бўлмади';

  @override
  String get thisMonthLabel => 'Шу ой';

  @override
  String get transactionStats => 'Амалиёт статистикаси';

  @override
  String get averageTransaction => 'Ўртача амалиёт';

  @override
  String get periodComparison => 'Давр таққослаш';

  @override
  String get todayVsYesterday => 'Бугун ва Кеча';

  @override
  String get thisWeekVsLast => 'Шу ҳафта ва Ўтган';

  @override
  String get thisMonthVsLast => 'Шу ой ва Ўтган';

  @override
  String get yesterday => 'Кеча';

  @override
  String get appearance => 'Кўриниш';

  @override
  String get darkMode => 'Тунги режим';

  @override
  String get themeSystem => 'Тизим';

  @override
  String get themeLight => 'Кундузги';

  @override
  String get themeDark => 'Тунги';

  @override
  String get currency => 'Валюта';

  @override
  String get selectCurrency => 'Валютани танланг';

  @override
  String get data => 'Маълумотлар';

  @override
  String get syncData => 'Синхронлаш';

  @override
  String get clearCache => 'Кешни тозалаш';

  @override
  String get clearCacheConfirm =>
      'Кешдаги маълумотлар ўчирилади. Кейин қайта синхронлаш талаб қилинади.';

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
  String get logoutConfirm => 'Ҳақиқатан ҳам чиқмоқчимисиз?';

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
      'Товарлар, мижозлар ва тоифаларни оффлайн режимда ишлатиш учун серверга уланинг.';

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
    return '$count та кутилаётган оффлайн амал';
  }

  @override
  String get currencyUzs => 'Ўзбек сўми';

  @override
  String get currencyUsd => 'АҚШ доллари';

  @override
  String get currencyEur => 'Евро';

  @override
  String get currencyRub => 'Россия рубли';

  @override
  String get alerts => 'Огоҳлантиришлар';

  @override
  String get markAllRead => 'Барчасини ўқилган қилиш';

  @override
  String get noAlerts => 'Огоҳлантириш йўқ';

  @override
  String get unread => 'Ўқилмаган';

  @override
  String get allCaughtUp => 'Ҳаммаси ўқилган!';

  @override
  String get noAlertsToShow => 'Кўрсатиш учун огоҳлантириш йўқ';

  @override
  String get alertLowStock => 'Кам қолган';

  @override
  String get alertOutOfStock => 'Тугаган';

  @override
  String get alertExpiring => 'Муддати тугамоқда';

  @override
  String get alertTransaction => 'Амалиёт';

  @override
  String get alertSummary => 'Хулоса';

  @override
  String get alertPriceChange => 'Нарх ўзгарди';

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
  String get somethingWentWrong => 'Хатолик юз берди';

  @override
  String get tryAgain => 'Қайта уриниб кўринг';

  @override
  String get noInternetConnection => 'Интернет алоқаси йўқ';

  @override
  String get checkConnection =>
      'Интернет алоқасини текширинг ва қайта уриниб кўринг';

  @override
  String get sessionExpired => 'Сессия муддати тугади';

  @override
  String get pleaseLoginAgain => 'Илтимос, қайтадан киринг';

  @override
  String get success => 'Муваффақият';

  @override
  String get confirm => 'Тасдиқлаш';

  @override
  String get delete => 'Ўчириш';

  @override
  String get edit => 'Таҳрирлаш';

  @override
  String get close => 'Ёпиш';

  @override
  String get search => 'Қидириш';

  @override
  String get filter => 'Фильтр';

  @override
  String get sortBy => 'Саралаш';

  @override
  String get date => 'Сана';

  @override
  String get from => 'Дан';

  @override
  String get to => 'Гача';

  @override
  String get quantity => 'Сони';

  @override
  String get price => 'Нарх';

  @override
  String get description => 'Тавсиф';

  @override
  String get name => 'Ном';

  @override
  String get phone => 'Телефон';

  @override
  String get email => 'Электрон почта';

  @override
  String get address => 'Манзил';

  @override
  String get loading => 'Юкланмоқда...';

  @override
  String get retry => 'Қайта уриниш';

  @override
  String get error => 'Хатолик';

  @override
  String get noData => 'Маълумот мавжуд эмас';
}
