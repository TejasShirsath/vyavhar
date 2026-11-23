import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'sample_data.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vyavhar.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN image_path TEXT');
      } catch (_) {}
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        icon_name TEXT
      )
    ''');

    // 2. Products Table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sku TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL,
        purchase_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        current_stock REAL NOT NULL DEFAULT 0.0,
        unit TEXT NOT NULL DEFAULT 'piece',
        min_stock_alert REAL NOT NULL DEFAULT 5.0,
        supplier_name TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // 3. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        image_path TEXT,
        total_purchases REAL NOT NULL DEFAULT 0.0,
        pending_balance REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Suppliers Table
    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        total_supplied REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_id TEXT,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        customer_address TEXT,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        gst_rate REAL NOT NULL DEFAULT 0.0,
        gst_amount REAL NOT NULL DEFAULT 0.0,
        additional_charges REAL NOT NULL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        payment_status TEXT NOT NULL DEFAULT 'Paid',
        payment_mode TEXT NOT NULL DEFAULT 'Cash',
        notes TEXT,
        created_at TEXT NOT NULL,
        is_cancelled INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 6. Invoice Items Table
    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        sku TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL,
        purchase_price REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_amount REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 7. Invoice Delivery Photos Table
    await db.execute('''
      CREATE TABLE invoice_photos (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        photo_path TEXT NOT NULL,
        caption TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 8. Stock Movement History Table
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_value REAL NOT NULL,
        reference_id TEXT,
        reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 9. Wastage Records Table
    await db.execute('''
      CREATE TABLE wastage_records (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'piece',
        unit_cost REAL NOT NULL,
        total_loss REAL NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 10. Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 11. Business Settings Profile Table
    await db.execute('''
      CREATE TABLE business_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        business_name TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT NOT NULL,
        gstin TEXT,
        tagline TEXT NOT NULL,
        invoice_terms TEXT,
        currency_symbol TEXT NOT NULL DEFAULT '₹',
        logo_path TEXT
      )
    ''');

    // Indexes for fast lookups
    await db.execute('CREATE INDEX idx_products_sku ON products(sku)');
    await db.execute('CREATE INDEX idx_products_category ON products(category)');
    await db.execute('CREATE INDEX idx_invoices_number ON invoices(invoice_number)');
    await db.execute('CREATE INDEX idx_invoices_date ON invoices(created_at)');
    await db.execute('CREATE INDEX idx_movements_product ON stock_movements(product_id)');
    await db.execute('CREATE INDEX idx_movements_date ON stock_movements(created_at)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');

    // Seed realistic initial business data
    await SampleDataSeeder.seedDatabase(db);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> clearAllData({bool preserveProfile = true}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('invoice_photos');
      await txn.delete('invoice_items');
      await txn.delete('invoices');
      await txn.delete('stock_movements');
      await txn.delete('wastage_records');
      await txn.delete('expenses');
      await txn.delete('products');
      await txn.delete('customers');
      await txn.delete('suppliers');
      await txn.delete('categories');
      if (!preserveProfile) {
        await txn.delete('business_profile');
      }
    });
  }

  Future<void> resetToSampleData() async {
    await clearAllData(preserveProfile: false);
    final db = await database;
    await SampleDataSeeder.seedDatabase(db);
  }
}
