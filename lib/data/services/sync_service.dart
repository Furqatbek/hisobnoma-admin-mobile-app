import 'dart:async';
import 'dart:convert';

import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/api_endpoints.dart';
import 'package:hisobnoma/core/network/connectivity_checker.dart';
import 'package:hisobnoma/data/local/database_helper.dart';
import 'package:hisobnoma/data/repositories/sync_repository.dart';

/// Orchestrates offline sync: incremental data pull, full sync on first launch,
/// background sync on app resume, and offline queue processing.
class SyncService {
  final SyncRepository _syncRepository;
  final ApiClient _apiClient;
  final DatabaseHelper _databaseHelper;
  final ConnectivityChecker _connectivityChecker;

  final _statusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<bool>? _connectivitySub;
  Timer? _periodicTimer;
  bool _isSyncing = false;

  SyncService({
    required SyncRepository syncRepository,
    required ApiClient apiClient,
    required DatabaseHelper databaseHelper,
    required ConnectivityChecker connectivityChecker,
  }) : _syncRepository = syncRepository,
       _apiClient = apiClient,
       _databaseHelper = databaseHelper,
       _connectivityChecker = connectivityChecker;

  /// Stream of sync status updates
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Start listening for connectivity changes and schedule periodic sync
  void initialize() {
    // Sync when connectivity is restored
    _connectivitySub = _connectivityChecker.onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) syncAll();
    });

    // Periodic sync every 15 minutes
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => syncAll(),
    );
  }

  /// Run a full sync cycle: process offline queue, then pull latest data.
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    _statusController.add(const SyncStatus.syncing());

    try {
      final isOnline = await _connectivityChecker.checkConnectivity();
      if (!isOnline) {
        _statusController.add(const SyncStatus.offline());
        _isSyncing = false;
        return;
      }

      // 1. Process queued offline actions first
      await _processOfflineQueue();

      // 2. Pull latest data
      final results = await Future.wait([
        _syncProducts(),
        _syncCustomers(),
        _syncCategories(),
      ]);

      final totalSynced = results.fold<int>(0, (sum, count) => sum + count);

      _statusController.add(
        SyncStatus.completed(syncedAt: DateTime.now(), itemCount: totalSynced),
      );
    } catch (e) {
      _statusController.add(SyncStatus.error(message: e.toString()));
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync only products
  Future<int> syncProducts() => _syncProducts();

  /// Sync only customers
  Future<int> syncCustomers() => _syncCustomers();

  /// Sync only categories
  Future<int> syncCategories() => _syncCategories();

  /// Get counts for each synced entity (for sync info display)
  Future<SyncInfo> getSyncInfo() async {
    final productsLastSync = await _databaseHelper.getLastSyncAt('products');
    final customersLastSync = await _databaseHelper.getLastSyncAt('customers');
    final categoriesLastSync = await _databaseHelper.getLastSyncAt(
      'categories',
    );

    final db = await _databaseHelper.database;
    final productCount =
        (await db.rawQuery('SELECT COUNT(*) as c FROM products')).first['c']
            as int;
    final customerCount =
        (await db.rawQuery('SELECT COUNT(*) as c FROM customers')).first['c']
            as int;
    final categoryCount =
        (await db.rawQuery('SELECT COUNT(*) as c FROM categories')).first['c']
            as int;
    final pendingActions = (await _databaseHelper.getPendingActions()).length;

    return SyncInfo(
      productCount: productCount,
      customerCount: customerCount,
      categoryCount: categoryCount,
      pendingActions: pendingActions,
      productsLastSync: productsLastSync,
      customersLastSync: customersLastSync,
      categoriesLastSync: categoriesLastSync,
    );
  }

  /// Enqueue an offline action (e.g. quick sale done while offline)
  Future<void> enqueueOfflineAction(String actionType, Object payload) async {
    await _databaseHelper.enqueueAction(actionType, jsonEncode(payload));
  }

  // ---------------------------------------------------------------------------
  // Private sync methods
  // ---------------------------------------------------------------------------

  Future<int> _syncProducts() async {
    final lastSync = await _databaseHelper.getLastSyncAt('products');
    final response = await _syncRepository.syncProducts(lastSyncAt: lastSync);

    if (response.items.isNotEmpty) {
      final rows = response.items.map((p) => p.toDbRow()).toList();
      await _databaseHelper.upsertProducts(rows);
    }

    await _databaseHelper.setLastSyncAt('products', response.lastSyncAt);
    return response.count;
  }

  Future<int> _syncCustomers() async {
    final lastSync = await _databaseHelper.getLastSyncAt('customers');
    final response = await _syncRepository.syncCustomers(lastSyncAt: lastSync);

    if (response.items.isNotEmpty) {
      final rows = response.items.map((c) => c.toDbRow()).toList();
      await _databaseHelper.upsertCustomers(rows);
    }

    await _databaseHelper.setLastSyncAt('customers', response.lastSyncAt);
    return response.count;
  }

  Future<int> _syncCategories() async {
    final response = await _syncRepository.syncCategories();

    if (response.items.isNotEmpty) {
      final rows = response.items.map((c) => c.toDbRow()).toList();
      await _databaseHelper.upsertCategories(rows);
    }

    await _databaseHelper.setLastSyncAt('categories', response.lastSyncAt);
    return response.count;
  }

  Future<void> _processOfflineQueue() async {
    final pending = await _databaseHelper.getPendingActions();
    if (pending.isEmpty) return;

    for (final action in pending) {
      try {
        final type = action['action_type'] as String;
        final payload =
            jsonDecode(action['payload'] as String) as Map<String, dynamic>;

        await _executeQueuedAction(type, payload);
        await _databaseHelper.markActionSynced(action['id'] as int);
      } catch (_) {
        // Skip failed actions — will retry next cycle
      }
    }
  }

  Future<void> _executeQueuedAction(
    String type,
    Map<String, dynamic> payload,
  ) async {
    switch (type) {
      case 'quick_sale':
        await _apiClient.post(ApiEndpoints.quickSale, data: payload);
      case 'quick_count':
        await _apiClient.post(ApiEndpoints.quickCount, data: payload);
    }
  }

  /// Clean up resources
  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _statusController.close();
  }
}

// ---------------------------------------------------------------------------
// Sync status sealed class
// ---------------------------------------------------------------------------

sealed class SyncStatus {
  const SyncStatus();

  const factory SyncStatus.idle() = SyncIdle;
  const factory SyncStatus.syncing() = SyncSyncing;
  const factory SyncStatus.offline() = SyncOffline;
  const factory SyncStatus.completed({
    required DateTime syncedAt,
    required int itemCount,
  }) = SyncCompleted;
  const factory SyncStatus.error({required String message}) = SyncError;
}

class SyncIdle extends SyncStatus {
  const SyncIdle();
}

class SyncSyncing extends SyncStatus {
  const SyncSyncing();
}

class SyncOffline extends SyncStatus {
  const SyncOffline();
}

class SyncCompleted extends SyncStatus {
  final DateTime syncedAt;
  final int itemCount;

  const SyncCompleted({required this.syncedAt, required this.itemCount});
}

class SyncError extends SyncStatus {
  final String message;

  const SyncError({required this.message});
}

// ---------------------------------------------------------------------------
// Sync info data class
// ---------------------------------------------------------------------------

class SyncInfo {
  final int productCount;
  final int customerCount;
  final int categoryCount;
  final int pendingActions;
  final DateTime? productsLastSync;
  final DateTime? customersLastSync;
  final DateTime? categoriesLastSync;

  const SyncInfo({
    required this.productCount,
    required this.customerCount,
    required this.categoryCount,
    required this.pendingActions,
    this.productsLastSync,
    this.customersLastSync,
    this.categoriesLastSync,
  });

  bool get hasEverSynced =>
      productsLastSync != null ||
      customersLastSync != null ||
      categoriesLastSync != null;

  int get totalCount => productCount + customerCount + categoryCount;
}
