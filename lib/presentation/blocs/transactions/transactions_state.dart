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

class TransactionsDataLoaded extends TransactionsState {
  final List<InventoryProduct> products;
  final List<CustomerBalance> debtors;
  final List<SaleRecord> sales;

  const TransactionsDataLoaded({
    required this.products,
    required this.debtors,
    required this.sales,
  });

  @override
  List<Object?> get props => [products, debtors, sales];
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

class ActiveTerminalsLoaded extends TransactionsState {
  final List<PosTerminal> terminals;

  const ActiveTerminalsLoaded({required this.terminals});

  @override
  List<Object?> get props => [terminals];
}

class ActiveProductsLoaded extends TransactionsState {
  final List<ProductLookup> products;

  const ActiveProductsLoaded({required this.products});

  @override
  List<Object?> get props => [products];
}

class DeliveryRegionsLoaded extends TransactionsState {
  final List<DeliveryRegion> regions;

  const DeliveryRegionsLoaded({required this.regions});

  @override
  List<Object?> get props => [regions];
}

class DeliveryVillagesLoaded extends TransactionsState {
  final List<DeliveryVillage> villages;

  const DeliveryVillagesLoaded({required this.villages});

  @override
  List<Object?> get props => [villages];
}

class CustomersSearchLoaded extends TransactionsState {
  final List<Map<String, dynamic>> customers;
  final String query;

  const CustomersSearchLoaded({required this.customers, this.query = ''});

  @override
  List<Object?> get props => [customers, query];
}

class CustomerCreated extends TransactionsState {
  final Map<String, dynamic> customer;

  const CustomerCreated({required this.customer});

  @override
  List<Object?> get props => [customer];
}

class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError({required this.message});

  @override
  List<Object?> get props => [message];
}
