import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';

part 'transactions_state.dart';

class TransactionsCubit extends Cubit<TransactionsState> {
  final TransactionRepository _transactionRepository;

  TransactionsCubit({
    required TransactionRepository transactionRepository,
  })  : _transactionRepository = transactionRepository,
        super(const TransactionsInitial());

  void reset() => emit(const TransactionsInitial());

  /// Load inventory, debtors, and sales history in parallel
  Future<void> loadData() async {
    emit(const TransactionsLoading());
    try {
      List<InventoryProduct> products = [];
      List<CustomerBalance> debtors = [];
      List<SaleRecord> sales = [];

      await Future.wait([
        _transactionRepository.getInventoryProducts().then((r) {
          products = r.where((p) => p.active).toList();
        }),
        _transactionRepository.getCustomerBalances().then((report) {
          debtors = report.customerBalances
              .where((c) => c.netBalance > 0)
              .toList();
        }),
        _transactionRepository.getSalesHistory().then((r) {
          sales = r;
        }).catchError((Object _) {}),
      ]);

      emit(TransactionsDataLoaded(
        products: products,
        debtors: debtors,
        sales: sales,
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
