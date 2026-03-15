import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';

part 'transactions_state.dart';

class TransactionsCubit extends Cubit<TransactionsState> {
  final TransactionRepository _transactionRepository;

  TransactionsCubit({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(const TransactionsInitial());

  Future<void> searchProducts(String query) async {
    emit(const TransactionsLoading());
    try {
      final data = await _transactionRepository.searchProducts(query: query);
      emit(ProductsSearchLoaded(products: data.content));
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
