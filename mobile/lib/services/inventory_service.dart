import '../core/database/app_database.dart';
import '../core/utils/id_generator.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/wastage_record.dart';

class InventoryService {
  final AppDatabase _db = AppDatabase.instance;

  // --- Product Management ---

  Future<List<Product>> getProducts({String? category, String? query}) async {
    final db = await _db.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    if (query != null && query.trim().isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(name LIKE ? OR sku LIKE ?)';
      whereArgs.add('%${query.trim()}%');
      whereArgs.add('%${query.trim()}%');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<String> generateNextSku() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT sku FROM products WHERE sku LIKE "VYV-%"'
    );
    int maxSeq = 1000;
    for (final row in maps) {
      final skuStr = row['sku'] as String? ?? '';
      final numPart = int.tryParse(skuStr.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numPart != null && numPart > maxSeq) {
        maxSeq = numPart;
      }
    }
    return 'VYV-${maxSeq + 1}';
  }

  Future<Product> addProduct({
    required String name,
    required String category,
    required double purchasePrice,
    required double sellingPrice,
    required double initialStock,
    String unit = 'piece',
    double minStockAlert = 5.0,
    String? supplierName,
    String? imagePath,
  }) async {
    final db = await _db.database;
    final id = IdGenerator.uuid();
    final sku = await generateNextSku();
    final now = DateTime.now();

    final product = Product(
      id: id,
      name: name,
      sku: sku,
      category: category,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      currentStock: initialStock,
      unit: unit,
      minStockAlert: minStockAlert,
      supplierName: supplierName,
      imagePath: imagePath,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('products', product.toMap());

      if (initialStock > 0) {
        final movement = StockMovement(
          id: IdGenerator.uuid(),
          productId: id,
          movementType: 'INITIAL',
          quantity: initialStock,
          unitPrice: purchasePrice,
          totalValue: initialStock * purchasePrice,
          referenceId: null,
          reason: 'Initial opening stock',
          createdAt: now,
        );
        await txn.insert('stock_movements', movement.toMap());
      }
    });

    return product;
  }

  Future<void> updateProduct(Product product) async {
    final db = await _db.database;
    final updated = product.copyWith(updatedAt: DateTime.now());
    await db.update(
      'products',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await _db.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Stock Movement & Weighted Average Cost Calculation ---

  /// Records new purchase stock.
  /// Automatically computes new Weighted Average Purchase Cost (WAC):
  /// new_cost = ((current_stock * current_cost) + (purchased_qty * purchase_price)) / (current_stock + purchased_qty)
  Future<void> recordPurchaseStock({
    required String productId,
    required double quantity,
    required double purchasePrice,
    String? supplierName,
    DateTime? purchaseDate,
  }) async {
    final db = await _db.database;
    final date = purchaseDate ?? DateTime.now();

    await db.transaction((txn) async {
      final List<Map<String, dynamic>> maps = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (maps.isEmpty) throw Exception('Product not found');

      final current = Product.fromMap(maps.first);
      final currentStock = current.currentStock;
      final currentCost = current.purchasePrice;

      // Weighted Average Cost calculation
      double newCost;
      final newStock = currentStock + quantity;
      if (newStock > 0) {
        newCost = ((currentStock * currentCost) + (quantity * purchasePrice)) / newStock;
      } else {
        newCost = purchasePrice;
      }

      await txn.update(
        'products',
        {
          'current_stock': newStock,
          'purchase_price': newCost,
          if (supplierName != null && supplierName.isNotEmpty)
            'supplier_name': supplierName,
          'updated_at': date.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      // Record movement
      final movement = StockMovement(
        id: IdGenerator.uuid(),
        productId: productId,
        movementType: 'PURCHASE',
        quantity: quantity,
        unitPrice: purchasePrice,
        totalValue: quantity * purchasePrice,
        referenceId: null,
        reason: supplierName != null && supplierName.isNotEmpty
            ? 'Purchased from $supplierName'
            : 'Purchased inventory batch',
        createdAt: date,
      );
      await txn.insert('stock_movements', movement.toMap());
    });
  }

  /// Records product wastage (damaged, expired, spoiled, etc.)
  /// Automatically reduces current stock and records wastage loss at purchase cost.
  Future<void> recordWastage({
    required String productId,
    required double quantity,
    required String reason, // 'Expired', 'Damaged', 'Spoiled', 'Broken', 'Other'
    String? notes,
    DateTime? date,
  }) async {
    final db = await _db.database;
    final now = date ?? DateTime.now();

    await db.transaction((txn) async {
      final List<Map<String, dynamic>> maps = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (maps.isEmpty) throw Exception('Product not found');

      final product = Product.fromMap(maps.first);
      if (product.currentStock < quantity) {
        throw Exception(
          'Cannot waste $quantity ${product.unit}. Current stock is only ${product.currentStock} ${product.unit}.',
        );
      }

      final newStock = product.currentStock - quantity;
      final totalLoss = quantity * product.purchasePrice;

      await txn.update(
        'products',
        {
          'current_stock': newStock,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      final wastageId = IdGenerator.uuid();
      final wastageRecord = WastageRecord(
        id: wastageId,
        productId: productId,
        productName: product.name,
        quantity: quantity,
        unit: product.unit,
        unitCost: product.purchasePrice,
        totalLoss: totalLoss,
        reason: reason,
        notes: notes,
        createdAt: now,
      );
      await txn.insert('wastage_records', wastageRecord.toMap());

      final movement = StockMovement(
        id: IdGenerator.uuid(),
        productId: productId,
        movementType: 'WASTAGE',
        quantity: quantity,
        unitPrice: product.purchasePrice,
        totalValue: totalLoss,
        referenceId: wastageId,
        reason: 'Wastage: $reason${notes != null ? ' - $notes' : ''}',
        createdAt: now,
      );
      await txn.insert('stock_movements', movement.toMap());
    });
  }

  /// Get stock movements history for a specific product
  Future<List<StockMovement>> getProductMovements(String productId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  /// Get all recent stock movements across all products
  Future<List<StockMovement>> getAllStockMovements({int limit = 50}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT sm.*, p.name as product_name
      FROM stock_movements sm
      LEFT JOIN products p ON sm.product_id = p.id
      ORDER BY sm.created_at DESC
      LIMIT ?
    ''', [limit]);
    return maps.map((m) => StockMovement.fromMap(m, productName: m['product_name'] as String? ?? '')).toList();
  }

  /// Get inventory overview statistics
  Future<Map<String, dynamic>> getInventorySummary() async {
    final products = await getProducts();

    double totalStockValue = 0.0;
    double totalQuantity = 0.0;
    int lowStockCount = 0;
    int outOfStockCount = 0;

    for (final p in products) {
      totalStockValue += p.stockValue;
      totalQuantity += p.currentStock;
      if (p.isOutOfStock) {
        outOfStockCount++;
      } else if (p.isLowStock) {
        lowStockCount++;
      }
    }

    return {
      'totalProducts': products.length,
      'totalQuantity': totalQuantity,
      'totalStockValue': totalStockValue,
      'lowStockCount': lowStockCount,
      'outOfStockCount': outOfStockCount,
      'availableCount': products.length - outOfStockCount,
    };
  }

  Future<List<String>> getCategories() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name ASC',
    );
    final list = maps.map((m) => m['name'] as String).toList();
    if (!list.contains('Snacks')) list.insert(0, 'Snacks');
    if (!list.contains('Beverages')) list.insert(1, 'Beverages');
    if (!list.contains('Raw Material')) list.insert(2, 'Raw Material');
    return ['All', ...list.toSet()];
  }
}
