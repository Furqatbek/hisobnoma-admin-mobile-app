// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Хисобнома';

  @override
  String get home => 'Главная';

  @override
  String get transactions => 'Транзакции';

  @override
  String get reports => 'Отчёты';

  @override
  String get settings => 'Настройки';

  @override
  String get login => 'Войти';

  @override
  String get logout => 'Выйти';

  @override
  String get selectAccount => 'Выберите аккаунт';

  @override
  String get enterPin => 'Введите PIN';

  @override
  String get pleaseEnterPin => 'Пожалуйста, введите ваш PIN-код';

  @override
  String get financialTrackingTagline => 'Финансовый учёт стал проще';

  @override
  String get currentBalance => 'Текущий баланс';

  @override
  String get revenue => 'Доход';

  @override
  String get expenses => 'Расходы';

  @override
  String get inventoryOverview => 'Обзор склада';

  @override
  String get financialOverview => 'Финансовый обзор';

  @override
  String get goodMorning => 'Доброе утро';

  @override
  String get goodAfternoon => 'Добрый день';

  @override
  String get goodEvening => 'Добрый вечер';

  @override
  String get unableToLoadDashboard => 'Не удалось загрузить панель';

  @override
  String couldNotLoad(String sections) {
    return 'Не удалось загрузить: $sections';
  }

  @override
  String get thisMonth => 'за месяц';

  @override
  String get today => 'Сегодня';

  @override
  String get thisWeek => 'Эта неделя';

  @override
  String get revenueTrend => 'Тренд доходов';

  @override
  String get day => 'День';

  @override
  String get week => 'Неделя';

  @override
  String get month => 'Месяц';

  @override
  String get year => 'Год';

  @override
  String get noChartData => 'Нет данных для графика';

  @override
  String get avgTransaction => 'Сред. транзакция';

  @override
  String get activeSkus => 'Активные SKU';

  @override
  String get lowStock => 'Мало на складе';

  @override
  String get outOfStock => 'Нет в наличии';

  @override
  String get totalValue => 'Общая стоимость';

  @override
  String get expiringSoon => 'Скоро истекает';

  @override
  String get totalSkus => 'Всего SKU';

  @override
  String get netCashPosition => 'Чистая денежная позиция';

  @override
  String get bankBalance => 'Банковский баланс';

  @override
  String get cashBalance => 'Остаток наличных';

  @override
  String get receivableAr => 'Дебиторская задолж.';

  @override
  String get payableAp => 'Кредиторская задолж.';

  @override
  String txnCount(String count) {
    return '$count транз.';
  }

  @override
  String get addTransaction => 'Добавить транзакцию';

  @override
  String get income => 'Доход';

  @override
  String get expense => 'Расход';

  @override
  String get all => 'Все';

  @override
  String get amount => 'Сумма';

  @override
  String get notes => 'Заметки';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get searchProducts => 'Поиск товаров';

  @override
  String get searchProductsHint => 'Поиск товаров...';

  @override
  String get searchProductsByNameSku => 'Поиск товаров по названию или SKU...';

  @override
  String get products => 'Товары';

  @override
  String get quickSale => 'Быстрая продажа';

  @override
  String get quickCount => 'Быстрый подсчёт';

  @override
  String get tapSearchToFind =>
      'Нажмите на поиск для поиска товаров по названию, SKU или штрихкоду';

  @override
  String get noResults => 'Нет результатов';

  @override
  String noProductsFoundFor(String query) {
    return 'Товары не найдены для \"$query\"';
  }

  @override
  String get searchForProducts =>
      'Ищите товары по названию, SKU или сканируйте штрихкод';

  @override
  String get sellingPrice => 'Цена продажи';

  @override
  String get costPrice => 'Себестоимость';

  @override
  String get totalStock => 'Общий запас';

  @override
  String get barcode => 'Штрихкод';

  @override
  String get stockByLocation => 'Запас по локации';

  @override
  String availOnHand(String available, String onHand) {
    return '$available доступно · $onHand в наличии';
  }

  @override
  String get addToQuickSale => 'Добавить в продажу';

  @override
  String get saleCompleted => 'Продажа завершена';

  @override
  String get createQuickSaleHint =>
      'Создайте быструю продажу нажав кнопку ниже';

  @override
  String get newSale => 'Новая продажа';

  @override
  String get total => 'Итого';

  @override
  String get paid => 'Оплачено';

  @override
  String get change => 'Сдача';

  @override
  String get status => 'Статус';

  @override
  String get time => 'Время';

  @override
  String get quickCountHint =>
      'Выберите товар во вкладке Товары, затем выполните подсчёт';

  @override
  String get systemQty => 'Системное кол-во';

  @override
  String get countedQty => 'Подсчитано';

  @override
  String get variance => 'Разница';

  @override
  String get untracked => 'Не отслеживается';

  @override
  String inStock(String stock) {
    return '$stock на складе';
  }

  @override
  String cartCount(String count) {
    return 'Корзина ($count)';
  }

  @override
  String get searchToAdd => 'Найдите товар для добавления';

  @override
  String get noProductsFound => 'Товары не найдены';

  @override
  String get addMoreItems => 'Добавить ещё';

  @override
  String get clearAll => 'Очистить всё';

  @override
  String get cash => 'Наличные';

  @override
  String get card => 'Карта';

  @override
  String completeSale(String amount) {
    return 'Завершить продажу · $amount';
  }

  @override
  String saleCompletedAmount(String amount) {
    return 'Продажа завершена · $amount';
  }

  @override
  String get failedToCompleteSale => 'Не удалось завершить продажу';

  @override
  String get revenueOverview => 'Обзор доходов';

  @override
  String get incomeVsExpense => 'Доходы и Расходы';

  @override
  String get categoryBreakdown => 'По категориям';

  @override
  String get unableToLoadReports => 'Не удалось загрузить отчёты';

  @override
  String get thisMonthLabel => 'Этот месяц';

  @override
  String get transactionStats => 'Статистика транзакций';

  @override
  String get averageTransaction => 'Средняя транзакция';

  @override
  String get periodComparison => 'Сравнение периодов';

  @override
  String get todayVsYesterday => 'Сегодня и Вчера';

  @override
  String get thisWeekVsLast => 'Эта неделя и Прошлая';

  @override
  String get thisMonthVsLast => 'Этот месяц и Прошлый';

  @override
  String get yesterday => 'Вчера';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get darkMode => 'Тёмный режим';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get currency => 'Валюта';

  @override
  String get selectCurrency => 'Выберите валюту';

  @override
  String get data => 'Данные';

  @override
  String get syncData => 'Синхронизация';

  @override
  String get clearCache => 'Очистить кеш';

  @override
  String get clearCacheConfirm =>
      'Кешированные данные будут удалены. Возможно потребуется повторная синхронизация.';

  @override
  String get clear => 'Очистить';

  @override
  String get cacheCleared => 'Кеш очищен';

  @override
  String get notifications => 'Уведомления';

  @override
  String get alertPreferences => 'Настройки оповещений';

  @override
  String get devices => 'Устройства';

  @override
  String get account => 'Аккаунт';

  @override
  String get logoutConfirm => 'Вы уверены, что хотите выйти?';

  @override
  String get appVersion => 'Хисобнома v1.0.0';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get languageEn => 'English';

  @override
  String get languageUz => 'Ўзбекча';

  @override
  String get languageRu => 'Русский';

  @override
  String get dataSync => 'Синхронизация данных';

  @override
  String get syncDescription =>
      'Синхронизируйте товары, клиентов и категории с сервера для автономной работы.';

  @override
  String get syncNow => 'Синхронизировать';

  @override
  String get syncing => 'Синхронизация...';

  @override
  String itemsSynced(String count) {
    return '$count синхронизировано';
  }

  @override
  String pendingOfflineActions(String count) {
    return '$count ожидающих офлайн действий';
  }

  @override
  String get currencyUzs => 'Узбекский сум';

  @override
  String get currencyUsd => 'Доллар США';

  @override
  String get currencyEur => 'Евро';

  @override
  String get currencyRub => 'Российский рубль';

  @override
  String get alerts => 'Оповещения';

  @override
  String get markAllRead => 'Отметить все как прочитанные';

  @override
  String get noAlerts => 'Нет оповещений';

  @override
  String get unread => 'Непрочитанные';

  @override
  String get allCaughtUp => 'Всё прочитано!';

  @override
  String get noAlertsToShow => 'Нет оповещений для показа';

  @override
  String get alertLowStock => 'Мало на складе';

  @override
  String get alertOutOfStock => 'Нет в наличии';

  @override
  String get alertExpiring => 'Истекает';

  @override
  String get alertTransaction => 'Транзакция';

  @override
  String get alertSummary => 'Сводка';

  @override
  String get alertPriceChange => 'Изменение цены';

  @override
  String get alertNewOrder => 'Новый заказ';

  @override
  String get alertPayment => 'Оплата';

  @override
  String get alertPaymentDue => 'Срок оплаты';

  @override
  String get alertOverdue => 'Просрочено';

  @override
  String get alertSystem => 'Системное';

  @override
  String get priorityLow => 'Низкий';

  @override
  String get priorityNormal => 'Обычный';

  @override
  String get priorityHigh => 'Высокий';

  @override
  String get priorityUrgent => 'Срочный';

  @override
  String get customers => 'Клиенты';

  @override
  String get categories => 'Категории';

  @override
  String get loading => 'Загрузка...';

  @override
  String get retry => 'Повторить';

  @override
  String get error => 'Ошибка';

  @override
  String get noData => 'Нет данных';
}
