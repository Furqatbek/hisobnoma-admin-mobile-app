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

  /// Exposed for direct access by widgets that need to call repo methods
  /// without going through cubit state (e.g. loading terminals, regions).
  TransactionRepository get transactionRepository => _transactionRepository;

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
        _transactionRepository.getTransactions().then((r) {
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

  /// Load active POS terminals
  Future<void> loadActiveTerminals() async {
    try {
      final terminals = await _transactionRepository.getActiveTerminals();
      emit(ActiveTerminalsLoaded(terminals: terminals));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  /// Load active products for POS cart
  Future<void> loadActiveProducts({int page = 0, int size = 50}) async {
    emit(const TransactionsLoading());
    try {
      final data = await _transactionRepository.getActiveProducts(
        page: page,
        size: size,
      );
      emit(ActiveProductsLoaded(products: data.content));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  /// Load delivery regions
  Future<void> loadDeliveryRegions() async {
    try {
      final regions = await _transactionRepository.getDeliveryRegions();
      emit(DeliveryRegionsLoaded(regions: regions));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  /// Load delivery villages for a region
  Future<void> loadDeliveryVillages(int regionId) async {
    try {
      final villages =
          await _transactionRepository.getDeliveryVillages(regionId);
      emit(DeliveryVillagesLoaded(villages: villages));
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

  Future<void> searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      emit(const CustomersSearchLoaded(customers: []));
      return;
    }
    emit(const TransactionsLoading());
    try {
      final data = await _transactionRepository.searchCustomers(query: query);
      emit(CustomersSearchLoaded(customers: data.content, query: query));
    } catch (e) {
      emit(TransactionsError(message: e.toString()));
    }
  }

  /// Create a new finance customer (for debt sale)
  Future<void> createCustomer({
    required String name,
    String? phone,
  }) async {
    emit(const TransactionsLoading());
    try {
      final customer = await _transactionRepository.createFinanceCustomer(
        name: name,
        phone: phone,
      );
      emit(CustomerCreated(customer: customer));
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
