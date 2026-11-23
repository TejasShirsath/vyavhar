import 'package:sqflite/sqflite.dart';
import '../core/database/app_database.dart';
import '../core/utils/id_generator.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';

class CustomerService {
  final AppDatabase _db = AppDatabase.instance;

  // --- Customers ---

  Future<List<Customer>> getCustomers({String? searchQuery}) async {
    final db = await _db.database;
    String? where;
    List<dynamic>? whereArgs;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where = 'name LIKE ? OR phone LIKE ?';
      final q = '%${searchQuery.trim()}%';
      whereArgs = [q, q];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer> addCustomer({
    required String name,
    required String phone,
    String? address,
    String? imagePath,
  }) async {
    final db = await _db.database;
    final customer = Customer(
      id: IdGenerator.uuid(),
      name: name,
      phone: phone,
      address: address,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );
    await db.insert('customers', customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return customer;
  }

  Future<List<Invoice>> getCustomerInvoices(String customerPhone) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'customer_phone = ? AND is_cancelled = 0',
      whereArgs: [customerPhone],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  // --- Suppliers ---

  Future<List<Supplier>> getSuppliers() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'suppliers',
      orderBy: 'name ASC',
    );
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<Supplier> addSupplier({
    required String name,
    required String phone,
    String? address,
  }) async {
    final db = await _db.database;
    final supplier = Supplier(
      id: IdGenerator.uuid(),
      name: name,
      phone: phone,
      address: address,
      createdAt: DateTime.now(),
    );
    await db.insert('suppliers', supplier.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return supplier;
  }
}
