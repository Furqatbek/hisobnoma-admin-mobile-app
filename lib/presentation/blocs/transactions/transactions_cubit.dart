import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(ProductsSearchLoaded(data: data));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  Future<void> lookupBarcode(String barcode) async {
    emit(const TransactionsLoading());
    try {
      final data = await _transactionRepository.barcodeLookup(barcode);
      emit(BarcodeLookupLoaded(product: data));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  Future<void> createQuickSale({
    required int terminalId,
    int? customerId,
    required List<Map<String, dynamic>> items,
    required String paymentType,
    required double tenderedAmount,
    String? notes,
  }) async {
    emit(const TransactionsLoading());
    try {
      final data = await _transactionRepository.quickSale(
        terminalId: terminalId,
        customerId: customerId,
        items: items,
        paymentType: paymentType,
        tenderedAmount: tenderedAmount,
        notes: notes,
      );
      emit(QuickSaleCompleted(transaction: data));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  Future<void> quickCount({
    required int productId,
    required int locationId,
    required int countedQuantity,
    String? notes,
  }) async {
    emit(const TransactionsLoading());
    try {
      final data = await _transactionRepository.quickCount(
        productId: productId,
        locationId: locationId,
        countedQuantity: countedQuantity,
        notes: notes,
      );
      emit(QuickCountCompleted(result: data));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }
}
