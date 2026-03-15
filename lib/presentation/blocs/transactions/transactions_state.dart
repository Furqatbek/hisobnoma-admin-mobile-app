part of 'transactions_cubit.dart';

abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class ProductsSearchLoaded extends TransactionsState {
  final List<ProductLookup> products;
  final String query;

  const ProductsSearchLoaded({required this.products, this.query = ''});

  @override
  List<Object?> get props => [products, query];
}

class BarcodeLookupLoaded extends TransactionsState {
  final ProductLookup product;

  const BarcodeLookupLoaded({required this.product});

  @override
  List<Object?> get props => [product];
}

class QuickSaleCompleted extends TransactionsState {
  final QuickSaleResponse transaction;

  const QuickSaleCompleted({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class QuickCountCompleted extends TransactionsState {
  final QuickCountResponse result;

  const QuickCountCompleted({required this.result});

  @override
  List<Object?> get props => [result];
}

class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError({required this.message});

  @override
  List<Object?> get props => [message];
}
