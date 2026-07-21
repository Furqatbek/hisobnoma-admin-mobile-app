import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite database helper for offline sync data
class DatabaseHelper {
  static const _dbName = 'hisobnoma.db';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        sku TEXT NOT NULL,
        barcode TEXT,
        name TEXT NOT NULL,
        category_id INTEGER,
        category_name TEXT,
        selling_price REAL NOT NULL DEFAULT 0,
        cost_price REAL NOT NULL DEFAULT 0,
        unit_of_measure TEXT DEFAULT 'pcs',
        track_inventory INTEGER NOT NULL DEFAULT 1,
        active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        price_list_id INTEGER,
        credit_limit REAL DEFAULT 0,
        current_balance REAL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id INTEGER,
        sort_order INTEGER DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_metadata (
        entity TEXT PRIMARY KEY,
        last_sync_at TEXT NOT NULL,
        sync_version TEXT DEFAULT '1.0'
      )
    ''');

    // Offline action queue for operations done without connectivity
    await db.execute('''
      CREATE TABLE offline_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Indexes for search performance
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_sku ON products(sku)');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_customers_code ON customers(code)');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // === Products ===

  Future<void> upsertProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    final batch = db.batch();
    for (final product in products) {
      batch.insert('products', {
        'id': product['id'],
        'sku': product['sku'],
        'barcode': product['barcode'],
        'name': product['name'],
        'category_id': product['categoryId'],
        'category_name': product['categoryName'],
        'selling_price': product['sellingPrice'],
        'cost_price': product['costPrice'],
        'unit_of_measure': product['unitOfMeasure'],
        'track_inventory': product['trackInventory'] == true ? 1 : 0,
        'active': product['active'] == true ? 1 : 0,
        'updated_at': product['updatedAt'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return db.query(
      'products',
      where: 'active = 1 AND (name LIKE ? OR sku LIKE ? OR barcode LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      limit: 20,
    );
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'barcode = ? AND active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // === Customers ===

  Future<void> upsertCustomers(List<Map<String, dynamic>> customers) async {
    final db = await database;
    final batch = db.batch();
    for (final customer in customers) {
      batch.insert('customers', {
        'id': customer['id'],
        'code': customer['code'],
        'name': customer['name'],
        'phone': customer['phone'],
        'email': customer['email'],
        'price_list_id': customer['priceListId'],
        'credit_limit': customer['creditLimit'],
        'current_balance': customer['currentBalance'],
        'active': customer['active'] == true ? 1 : 0,
        'updated_at': customer['updatedAt'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final db = await database;
    return db.query(
      'customers',
      where: 'active = 1 AND (name LIKE ? OR code LIKE ? OR phone LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      limit: 20,
    );
  }

  // === Categories ===

  Future<void> upsertCategories(List<Map<String, dynamic>> categories) async {
    final db = await database;
    final batch = db.batch();
    for (final category in categories) {
      batch.insert('categories', {
        'id': category['id'],
        'name': category['name'],
        'parent_id': category['parentId'],
        'sort_order': category['sortOrder'],
        'active': category['active'] == true ? 1 : 0,
        'updated_at': category['updatedAt'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query(
      'categories',
      where: 'active = 1',
      orderBy: 'sort_order ASC',
    );
  }

  // === Sync Metadata ===

  Future<DateTime?> getLastSyncAt(String entity) async {
    final db = await database;
    final results = await db.query(
      'sync_metadata',
      where: 'entity = ?',
      whereArgs: [entity],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DateTime.tryParse(results.first['last_sync_at'] as String);
  }

  Future<void> setLastSyncAt(String entity, DateTime syncAt) async {
    final db = await database;
    await db.insert('sync_metadata', {
      'entity': entity,
      'last_sync_at': syncAt.toIso8601String(),
      'sync_version': '1.0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // === Offline Queue ===

  Future<void> enqueueAction(String actionType, String payload) async {
    final db = await database;
    await db.insert('offline_queue', {
      'action_type': actionType,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    return db.query(
      'offline_queue',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markActionSynced(int id) async {
    final db = await database;
    await db.update(
      'offline_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Utilities ===

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('products');
    await db.delete('customers');
    await db.delete('categories');
    await db.delete('sync_metadata');
    await db.delete('offline_queue');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
