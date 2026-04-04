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
  String get transactions => 'Операции';

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
  String get enterPin => 'Введите PIN-код';

  @override
  String get pleaseEnterPin => 'Пожалуйста, введите ваш PIN-код';

  @override
  String get financialTrackingTagline => 'Финансовый учёт — просто и удобно';

  @override
  String get currentBalance => 'Текущий баланс';

  @override
  String get revenue => 'Выручка';

  @override
  String get expenses => 'Расходы';

  @override
  String get inventoryOverview => 'Состояние склада';

  @override
  String get financialOverview => 'Финансы';

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
  String get thisWeek => 'За неделю';

  @override
  String get revenueTrend => 'Динамика выручки';

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
  String get avgTransaction => 'Сред. чек';

  @override
  String get activeSkus => 'Активные товары';

  @override
  String get lowStock => 'Мало на складе';

  @override
  String get outOfStock => 'Нет в наличии';

  @override
  String get totalValue => 'Общая стоимость';

  @override
  String get expiringSoon => 'Скоро истекает';

  @override
  String get totalSkus => 'Всего товаров';

  @override
  String get netCashPosition => 'Чистый остаток';

  @override
  String get bankBalance => 'На счетах';

  @override
  String get cashBalance => 'Наличные';

  @override
  String get receivableAr => 'Дебиторка';

  @override
  String get payableAp => 'Кредиторка';

  @override
  String txnCount(String count) {
    return '$count опер.';
  }

  @override
  String get addTransaction => 'Новая операция';

  @override
  String get income => 'Приход';

  @override
  String get expense => 'Расход';

  @override
  String get all => 'Все';

  @override
  String get amount => 'Сумма';

  @override
  String get notes => 'Заметка';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get searchProducts => 'Поиск товаров';

  @override
  String get searchProductsHint => 'Поиск товаров...';

  @override
  String get searchProductsByNameSku => 'Поиск по названию или SKU...';

  @override
  String get products => 'Товары';

  @override
  String get quickSale => 'Быстрая продажа';

  @override
  String get quickCount => 'Инвентаризация';

  @override
  String get tapSearchToFind =>
      'Используйте поиск для нахождения товаров по названию, SKU или штрихкоду';

  @override
  String get noResults => 'Ничего не найдено';

  @override
  String noProductsFoundFor(String query) {
    return 'По запросу \"$query\" ничего не найдено';
  }

  @override
  String get searchForProducts =>
      'Найдите товар по названию, SKU или отсканируйте штрихкод';

  @override
  String get sellingPrice => 'Цена продажи';

  @override
  String get costPrice => 'Себестоимость';

  @override
  String get totalStock => 'На складе';

  @override
  String get barcode => 'Штрихкод';

  @override
  String get stockByLocation => 'Остатки по складам';

  @override
  String availOnHand(String available, String onHand) {
    return '$available доступно · $onHand в наличии';
  }

  @override
  String get addToQuickSale => 'Добавить в продажу';

  @override
  String get saleCompleted => 'Продажа оформлена!';

  @override
  String get createQuickSaleHint =>
      'Нажмите кнопку ниже чтобы оформить продажу';

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
      'Выберите товар во вкладке Товары, затем проведите подсчёт';

  @override
  String get systemQty => 'По системе';

  @override
  String get countedQty => 'Подсчитано';

  @override
  String get variance => 'Расхождение';

  @override
  String get untracked => 'Без учёта';

  @override
  String inStock(String stock) {
    return 'На складе: $stock';
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
  String get clearAll => 'Очистить';

  @override
  String get cash => 'Наличные';

  @override
  String get card => 'Карта';

  @override
  String completeSale(String amount) {
    return 'Оформить · $amount';
  }

  @override
  String saleCompletedAmount(String amount) {
    return 'Продано · $amount';
  }

  @override
  String get failedToCompleteSale => 'Ошибка при оформлении продажи';

  @override
  String productsFound(String count) {
    return 'Найдено: $count';
  }

  @override
  String get scanBarcode => 'Сканировать штрихкод';

  @override
  String get profitMargin => 'Маржа';

  @override
  String get swipeToRemove => 'Проведите для удаления';

  @override
  String get revenueOverview => 'Обзор выручки';

  @override
  String get incomeVsExpense => 'Приход и Расход';

  @override
  String get categoryBreakdown => 'По категориям';

  @override
  String get unableToLoadReports => 'Не удалось загрузить отчёты';

  @override
  String get thisMonthLabel => 'За месяц';

  @override
  String get transactionStats => 'Статистика операций';

  @override
  String get averageTransaction => 'Средний чек';

  @override
  String get periodComparison => 'Сравнение периодов';

  @override
  String get todayVsYesterday => 'Сегодня и Вчера';

  @override
  String get thisWeekVsLast => 'Эта и прошлая неделя';

  @override
  String get thisMonthVsLast => 'Этот и прошлый месяц';

  @override
  String get yesterday => 'Вчера';

  @override
  String get appearance => 'Оформление';

  @override
  String get darkMode => 'Тёмная тема';

  @override
  String get themeSystem => 'Авто';

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
      'Кешированные данные будут удалены. Потребуется повторная синхронизация.';

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
  String get dataSync => 'Синхронизация';

  @override
  String get syncDescription =>
      'Загрузите товары, клиентов и категории для работы без интернета.';

  @override
  String get syncNow => 'Синхронизировать';

  @override
  String get syncing => 'Синхронизация...';

  @override
  String itemsSynced(String count) {
    return 'Загружено: $count';
  }

  @override
  String pendingOfflineActions(String count) {
    return 'Ожидает отправки: $count';
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
  String get markAllRead => 'Прочитать все';

  @override
  String get noAlerts => 'Нет оповещений';

  @override
  String get unread => 'Непрочитанные';

  @override
  String get allCaughtUp => 'Всё прочитано!';

  @override
  String get noAlertsToShow => 'Нет оповещений';

  @override
  String get alertLowStock => 'Мало на складе';

  @override
  String get alertOutOfStock => 'Нет в наличии';

  @override
  String get alertExpiring => 'Истекает срок';

  @override
  String get alertTransaction => 'Операция';

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
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get tryAgain => 'Попробуйте ещё раз';

  @override
  String get noInternetConnection => 'Нет подключения к интернету';

  @override
  String get checkConnection =>
      'Проверьте подключение к интернету и попробуйте снова';

  @override
  String get sessionExpired => 'Сессия истекла';

  @override
  String get pleaseLoginAgain => 'Пожалуйста, войдите заново';

  @override
  String get success => 'Готово';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Изменить';

  @override
  String get close => 'Закрыть';

  @override
  String get search => 'Поиск';

  @override
  String get filter => 'Фильтр';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get date => 'Дата';

  @override
  String get from => 'С';

  @override
  String get to => 'По';

  @override
  String get quantity => 'Количество';

  @override
  String get price => 'Цена';

  @override
  String get description => 'Описание';

  @override
  String get name => 'Название';

  @override
  String get phone => 'Телефон';

  @override
  String get email => 'Эл. почта';

  @override
  String get address => 'Адрес';

  @override
  String get loading => 'Загрузка...';

  @override
  String get retry => 'Повторить';

  @override
  String get error => 'Ошибка';

  @override
  String get noData => 'Нет данных';
}
