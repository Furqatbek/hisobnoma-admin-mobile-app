import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/models/sync/sync_models.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/data/repositories/sync_repository.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';

part 'transactions_state.dart';

class TransactionsCubit extends Cubit<TransactionsState> {
  final TransactionRepository _transactionRepository;
  final SyncRepository _syncRepository;

  TransactionsCubit({
    required TransactionRepository transactionRepository,
    required SyncRepository syncRepository,
  })  : _transactionRepository = transactionRepository,
        _syncRepository = syncRepository,
        super(const TransactionsInitial());

  void reset() => emit(const TransactionsInitial());

  /// Load inventory, debtors, and creditors in parallel
  Future<void> loadData() async {
    emit(const TransactionsLoading());
    try {
      List<SyncProduct> products = [];
      List<SyncCustomer> debtors = [];
      List<SyncCustomer> creditors = [];

      await Future.wait([
        _syncRepository.syncProducts().then((r) {
          products = r.items.where((p) => p.active).toList();
        }),
        _syncRepository.syncCustomers().then((r) {
          final active = r.items.where((c) => c.active).toList();
          debtors = active.where((c) => c.currentBalance > 0).toList()
            ..sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
          creditors = active.where((c) => c.currentBalance < 0).toList()
            ..sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
        }),
      ]);

      emit(TransactionsDataLoaded(
        products: products,
        debtors: debtors,
        creditors: creditors,
      ));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      emit(const ProductsSearchLoaded(products: []));
      return;
    }
    emit(const TransactionsLoading());
    try {
      final data = await _transactionRepository.searchProducts(query: query);
      emit(ProductsSearchLoaded(products: data.content, query: query));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  Future<void> lookupBarcode(String barcode) async {
    emit(const TransactionsLoading());
    try {
      final product = await _transactionRepository.barcodeLookup(barcode);
      emit(BarcodeLookupLoaded(product: product));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  Future<void> createQuickSale(QuickSaleRequest request) async {
    emit(const TransactionsLoading());
    try {
      final result = await _transactionRepository.quickSale(request);
      emit(QuickSaleCompleted(transaction: result));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  Future<void> quickCount(QuickCountRequest request) async {
    emit(const TransactionsLoading());
    try {
      final result = await _transactionRepository.quickCount(request);
      emit(QuickCountCompleted(result: result));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }
}
