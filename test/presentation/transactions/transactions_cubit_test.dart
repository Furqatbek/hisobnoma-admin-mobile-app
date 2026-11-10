import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/data/models/transaction/customer_balance.dart';
import 'package:hisobnoma/data/models/transaction/inventory_product.dart';
import 'package:hisobnoma/data/models/transaction/sale_record.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TransactionRepository {}

const _emptyReport = CustomerBalanceReport(
  reportDate: '2026-11-10',
  customerBalances: [],
  totalReceivables: 0,
  totalCredits: 0,
  totalNetBalance: 0,
  customerCount: 0,
);

const _cement = InventoryProduct(
  id: 1,
  sku: 'CEM-450',
  barcode: '',
  name: 'Cement 450',
  baseUomCode: 'BAG',
  baseUomName: 'bag',
  costPrice: 40000,
  sellingPrice: 49000,
  trackInventory: true,
  active: true,
  margin: 0,
  markup: 0,
  stockQuantity: 10,
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(
      () => repo.getInventoryProducts(),
    ).thenAnswer((_) async => <InventoryProduct>[]);
    when(
      () => repo.getCustomerBalances(),
    ).thenAnswer((_) async => _emptyReport);
    when(() => repo.getTransactions()).thenAnswer((_) async => <SaleRecord>[]);
  });

  TransactionsCubit build() => TransactionsCubit(transactionRepository: repo);

  blocTest<TransactionsCubit, TransactionsState>(
    'first load shows the skeleton, then the data',
    build: build,
    act: (c) => c.loadData(),
    expect: () => [
      const TransactionsLoading(),
      const TransactionsDataLoaded(products: [], debtors: [], sales: []),
    ],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'first-load failure surfaces an error',
    build: build,
    setUp: () {
      when(() => repo.getInventoryProducts()).thenThrow(Exception('boom'));
    },
    act: (c) => c.loadData(),
    expect: () => [
      const TransactionsLoading(),
      const TransactionsError(message: 'boom'),
    ],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'a revisit refreshes silently — no skeleton between data states',
    build: build,
    act: (c) async {
      await c.loadData();
      when(
        () => repo.getInventoryProducts(),
      ).thenAnswer((_) async => [_cement]);
      await c.loadData();
    },
    expect: () => [
      const TransactionsLoading(),
      const TransactionsDataLoaded(products: [], debtors: [], sales: []),
      const TransactionsDataLoaded(products: [_cement], debtors: [], sales: []),
    ],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'a failed background refresh keeps the cached list on screen',
    build: build,
    act: (c) async {
      await c.loadData();
      when(() => repo.getInventoryProducts()).thenThrow(Exception('offline'));
      await c.loadData();
    },
    expect: () => [
      const TransactionsLoading(),
      const TransactionsDataLoaded(products: [], debtors: [], sales: []),
    ],
    verify: (c) {
      expect(c.state, isA<TransactionsDataLoaded>());
      expect(c.lastData, isNotNull);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'coming back from a search state restores the list instantly',
    build: build,
    act: (c) async {
      await c.loadData();
      await c.searchProducts(''); // emits ProductsSearchLoaded, no network
      when(
        () => repo.getInventoryProducts(),
      ).thenAnswer((_) async => [_cement]);
      await c.loadData();
    },
    expect: () => [
      const TransactionsLoading(),
      const TransactionsDataLoaded(products: [], debtors: [], sales: []),
      const ProductsSearchLoaded(products: []),
      // Cached list first (synchronously), fresh data after the fetch.
      const TransactionsDataLoaded(products: [], debtors: [], sales: []),
      const TransactionsDataLoaded(products: [_cement], debtors: [], sales: []),
    ],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'reset drops the cache so the next load shows the skeleton again',
    build: build,
    act: (c) async {
      await c.loadData();
      c.reset();
      await c.loadData();
    },
    expect: () => [
      const TransactionsLoading(),
      const TransactionsDataLoaded(products: [], debtors: [], sales: []),
      const TransactionsInitial(),
      const TransactionsLoading(),
      const TransactionsDataLoaded(products: [], debtors: [], sales: []),
    ],
  );
}
