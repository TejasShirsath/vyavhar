import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../core/database/app_database.dart';
import '../models/business_profile.dart';

class BusinessService {
  final AppDatabase _db = AppDatabase.instance;

  Future<BusinessProfile> getProfile() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'business_profile',
      where: 'id = 1',
      limit: 1,
    );
    if (maps.isEmpty) {
      return const BusinessProfile();
    }
    return BusinessProfile.fromMap(maps.first);
  }

  Future<void> updateProfile(BusinessProfile profile) async {
    final db = await _db.database;
    final map = profile.toMap()..['id'] = 1;
    await db.insert(
      'business_profile',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Exports all database tables as a JSON string for full offline backup
  Future<String> exportBackupJson() async {
    final db = await _db.database;
    final data = <String, dynamic>{
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'business_profile': await db.query('business_profile'),
      'categories': await db.query('categories'),
      'products': await db.query('products'),
      'customers': await db.query('customers'),
      'suppliers': await db.query('suppliers'),
      'invoices': await db.query('invoices'),
      'invoice_items': await db.query('invoice_items'),
      'invoice_photos': await db.query('invoice_photos'),
      'stock_movements': await db.query('stock_movements'),
      'wastage_records': await db.query('wastage_records'),
      'expenses': await db.query('expenses'),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Restores data from a backup JSON string
  Future<void> restoreBackupJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
    final db = await _db.database;

    await db.transaction((txn) async {
      // Clear existing
      for (final table in [
        'invoice_photos',
        'invoice_items',
        'invoices',
        'stock_movements',
        'wastage_records',
        'expenses',
        'products',
        'customers',
        'suppliers',
        'categories',
        'business_profile',
      ]) {
        await txn.delete(table);
      }

      // Re-insert
      for (final table in [
        'business_profile',
        'categories',
        'products',
        'customers',
        'suppliers',
        'invoices',
        'invoice_items',
        'invoice_photos',
        'stock_movements',
        'wastage_records',
        'expenses',
      ]) {
        final rows = data[table] as List<dynamic>?;
        if (rows != null) {
          for (final row in rows) {
            await txn.insert(table, Map<String, dynamic>.from(row as Map));
          }
        }
      }
    });
  }
}
