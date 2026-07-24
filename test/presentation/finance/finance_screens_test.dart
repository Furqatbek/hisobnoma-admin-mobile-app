import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hisobnoma/data/models/finance/finance_models.dart';
import 'package:hisobnoma/data/repositories/finance_repository.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/screens/finance/debtor_payment_screen.dart';
import 'package:hisobnoma/presentation/screens/finance/expense_screen.dart';
import 'package:hisobnoma/presentation/screens/finance/finance_form_widgets.dart';
import 'package:hisobnoma/presentation/screens/finance/salary_payment_screen.dart';

/// Fake repos that return canned data for the picker sheets without any
/// network. `implements` + noSuchMethod means we only stub what the screens
/// actually call when opening a picker.
class _FakeFinanceRepository implements FinanceRepository {
  @override
  Future<List<Employee>> getEmployees() async => const [
    Employee(id: 1, name: 'Ali Valiyev', position: 'Cashier'),
    Employee(id: 2, name: 'Vali Aliyev', position: 'Manager'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransactionRepository implements TransactionRepository {
  @override
  Future<List<Map<String, dynamic>>> getFinanceCustomers({
    int size = 1000,
    String sort = 'name,asc',
  }) async => const [
    {'id': 10, 'name': 'Test Customer', 'currentBalance': 250000.0},
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: child,
  );
}

/// Pump a few frames (sheet entry animation + async data load) without
/// pumpAndSettle, which would hang on the loading spinner's animation.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final getIt = GetIt.instance;

  setUp(() {
    getIt.registerSingleton<FinanceRepository>(_FakeFinanceRepository());
    getIt.registerSingleton<TransactionRepository>(
      _FakeTransactionRepository(),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('ExpenseScreen renders its form', (tester) async {
    await tester.pumpWidget(_wrap(const ExpenseScreen()));
    await tester.pump();
    expect(find.byType(AmountField), findsOneWidget);
  });

  testWidgets('DebtorPaymentScreen opens the customer picker without '
      'the ListTile/Material assertion', (tester) async {
    await tester.pumpWidget(_wrap(const DebtorPaymentScreen()));
    await tester.pump();

    // Open the customer picker.
    await tester.tap(find.byType(TextFormField).first);
    await _settle(tester);

    // The canned customer renders in a ListTile inside the decorated sheet —
    // if it weren't wrapped in a Material, a framework assertion would have
    // failed this test during the sheet build.
    expect(find.text('Test Customer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SalaryPaymentScreen opens the employee picker without '
      'the ListTile/Material assertion', (tester) async {
    await tester.pumpWidget(_wrap(const SalaryPaymentScreen()));
    await tester.pump();

    await tester.tap(find.byType(TextFormField).first);
    await _settle(tester);

    expect(find.text('Ali Valiyev'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
