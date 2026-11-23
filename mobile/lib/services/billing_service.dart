import 'package:sqflite/sqflite.dart';
import '../core/database/app_database.dart';
import '../core/utils/id_generator.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';

class BillingService {
  final AppDatabase _db = AppDatabase.instance;

  Future<String> generateNextInvoiceNumber() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT invoice_number FROM invoices WHERE invoice_number LIKE "INV-%"'
    );
    int maxSeq = 1000;
    for (final row in maps) {
      final invStr = row['invoice_number'] as String? ?? '';
      final numPart = int.tryParse(invStr.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numPart != null && numPart > maxSeq) {
        maxSeq = numPart;
      }
    }
    return 'INV-${maxSeq + 1}';
  }

  Future<Invoice> createInvoice({
    String? customerId,
    required String customerName,
    required String customerPhone,
    String? customerAddress,
    required List<Map<String, dynamic>> itemsData,
    double discount = 0.0,
    double gstRate = 0.0,
    double additionalCharges = 0.0,
    required double paidAmount,
    required String paymentMode,
    String? notes,
    List<String> photoPaths = const [],
    DateTime? date,
  }) async {
    final db = await _db.database;
    final now = date ?? DateTime.now();
    final invoiceId = IdGenerator.uuid();
    final invoiceNumber = await generateNextInvoiceNumber();

    // Calculate subtotal
    double subtotal = 0.0;
    for (final item in itemsData) {
      final qty = (item['quantity'] as num).toDouble();
      final price = (item['unitPrice'] as num).toDouble();
      subtotal += qty * price;
    }

    final discounted = (subtotal - discount).clamp(0.0, double.infinity);
    final gstAmount = (discounted * gstRate) / 100.0;
    final grandTotal = discounted + gstAmount + additionalCharges;

    String paymentStatus;
    if (paidAmount >= grandTotal) {
      paymentStatus = 'Paid';
    } else if (paidAmount > 0) {
      paymentStatus = 'Partial';
    } else {
      paymentStatus = 'Pending';
    }

    final invoice = Invoice(
      id: invoiceId,
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      subtotal: subtotal,
      discount: discount,
      gstRate: gstRate,
      gstAmount: gstAmount,
      additionalCharges: additionalCharges,
      grandTotal: grandTotal,
      paidAmount: paidAmount,
      paymentStatus: paymentStatus,
      paymentMode: paymentMode,
      notes: notes,
      createdAt: now,
      isCancelled: false,
    );

    await db.transaction((txn) async {
      // 1. Insert Invoice
      await txn.insert('invoices', invoice.toMap());

      // 2. Insert Items & Decrement Stock
      final List<InvoiceItem> invoiceItems = [];
      for (final item in itemsData) {
        final productId = item['productId'] as String;
        final qty = (item['quantity'] as num).toDouble();
        final unitPrice = (item['unitPrice'] as num).toDouble();
        final totalAmount = qty * unitPrice;

        // Fetch product to retrieve current purchase price (for COGS) and check stock
        final pMaps = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        if (pMaps.isEmpty) throw Exception('Product $productId not found');
        final product = Product.fromMap(pMaps.first);

        if (product.currentStock < qty) {
          // Warning if low stock, but allow sale with update
        }

        final invoiceItem = InvoiceItem(
          id: IdGenerator.uuid(),
          invoiceId: invoiceId,
          productId: productId,
          productName: product.name,
          sku: product.sku,
          unit: product.unit,
          quantity: qty,
          purchasePrice: product.purchasePrice,
          unitPrice: unitPrice,
          totalAmount: totalAmount,
        );

        await txn.insert('invoice_items', invoiceItem.toMap());
        invoiceItems.add(invoiceItem);

        // Deduct inventory
        final newStock = product.currentStock - qty;
        await txn.update(
          'products',
          {'current_stock': newStock, 'updated_at': now.toIso8601String()},
          where: 'id = ?',
          whereArgs: [productId],
        );

        // Record stock movement
        final movement = StockMovement(
          id: IdGenerator.uuid(),
          productId: productId,
          productName: product.name,
          movementType: 'SALE',
          quantity: qty,
          unitPrice: unitPrice,
          totalValue: totalAmount,
          referenceId: invoiceId,
          reason: 'Sold via $invoiceNumber to $customerName',
          createdAt: now,
        );
        await txn.insert('stock_movements', movement.toMap());
      }

      // 3. Save Delivery Photos
      for (final photo in photoPaths) {
        if (photo.trim().isNotEmpty) {
          await txn.insert('invoice_photos', {
            'id': IdGenerator.uuid(),
            'invoice_id': invoiceId,
            'photo_path': photo.trim(),
            'caption': 'Delivery verification for $customerName',
            'created_at': now.toIso8601String(),
          });
        }
      }

      // 4. Update or Create Customer Record
      final custMaps = await txn.query(
        'customers',
        where: 'phone = ?',
        whereArgs: [customerPhone],
        limit: 1,
      );

      final pendingOnBill = (grandTotal - paidAmount).clamp(0.0, double.infinity);

      if (custMaps.isNotEmpty) {
        final existingCust = custMaps.first;
        final updatedTotalPurchases =
            (existingCust['total_purchases'] as num).toDouble() + grandTotal;
        final updatedPendingBalance =
            (existingCust['pending_balance'] as num).toDouble() + pendingOnBill;

        await txn.update(
          'customers',
          {
            'name': customerName,
            if (customerAddress != null && customerAddress.isNotEmpty)
              'address': customerAddress,
            'total_purchases': updatedTotalPurchases,
            'pending_balance': updatedPendingBalance,
          },
          where: 'id = ?',
          whereArgs: [existingCust['id']],
        );
      } else {
        await txn.insert('customers', {
          'id': customerId ?? IdGenerator.uuid(),
          'name': customerName,
          'phone': customerPhone,
          'address': customerAddress,
          'total_purchases': grandTotal,
          'pending_balance': pendingOnBill,
          'created_at': now.toIso8601String(),
        });
      }
    });

    return await getInvoiceById(invoiceId) ?? invoice;
  }

  Future<List<Invoice>> getInvoices({
    String? status, // 'Paid', 'Pending', 'Partial', 'Cancelled'
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (status != null && status != 'All') {
      if (status == 'Cancelled') {
        where += 'is_cancelled = 1';
      } else if (status == 'Pending') {
        where += '(payment_status = "Pending" OR payment_status = "Partial") AND is_cancelled = 0';
      } else {
        where += 'payment_status = ? AND is_cancelled = 0';
        whereArgs.add(status);
      }
    } else {
      where += 'is_cancelled = 0';
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += '(invoice_number LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ?)';
      final q = '%${searchQuery.trim()}%';
      whereArgs.addAll([q, q, q]);
    }

    if (startDate != null && endDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'created_at BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
    );

    final List<Invoice> invoices = [];
    for (final map in maps) {
      final invId = map['id'] as String;
      final items = await _getInvoiceItems(db, invId);
      final photos = await _getInvoicePhotos(db, invId);
      invoices.add(Invoice.fromMap(map, items: items, photoPaths: photos));
    }
    return invoices;
  }

  Future<Invoice?> getInvoiceById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final items = await _getInvoiceItems(db, id);
    final photos = await _getInvoicePhotos(db, id);
    return Invoice.fromMap(maps.first, items: items, photoPaths: photos);
  }

  Future<List<InvoiceItem>> _getInvoiceItems(DatabaseExecutor db, String invoiceId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return maps.map((m) => InvoiceItem.fromMap(m)).toList();
  }

  Future<List<String>> _getInvoicePhotos(DatabaseExecutor db, String invoiceId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_photos',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => m['photo_path'] as String).toList();
  }

  /// Cancels an invoice, reverses stock movements back into inventory!
  Future<void> cancelInvoice(String invoiceId) async {
    final db = await _db.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final invMaps = await txn.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
        limit: 1,
      );
      if (invMaps.isEmpty) throw Exception('Invoice not found');
      final invoiceMap = invMaps.first;
      if ((invoiceMap['is_cancelled'] as int) == 1) {
        throw Exception('Invoice is already cancelled');
      }

      // 1. Mark as cancelled
      await txn.update(
        'invoices',
        {'is_cancelled': 1},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // 2. Fetch items and restore inventory
      final items = await _getInvoiceItems(txn, invoiceId);
      for (final item in items) {
        // Fetch current product stock
        final pMaps = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
          limit: 1,
        );
        if (pMaps.isNotEmpty) {
          final currentProduct = Product.fromMap(pMaps.first);
          final restoredStock = currentProduct.currentStock + item.quantity;
          await txn.update(
            'products',
            {'current_stock': restoredStock, 'updated_at': now.toIso8601String()},
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          // Record reverse movement
          final movement = StockMovement(
            id: IdGenerator.uuid(),
            productId: item.productId,
            movementType: 'RETURN',
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            totalValue: item.totalAmount,
            referenceId: invoiceId,
            reason: 'Restored due to cancellation of ${invoiceMap['invoice_number']}',
            createdAt: now,
          );
          await txn.insert('stock_movements', movement.toMap());
        }
      }

      // 3. Adjust customer balance
      final phone = invoiceMap['customer_phone'] as String;
      final custMaps = await txn.query(
        'customers',
        where: 'phone = ?',
        whereArgs: [phone],
        limit: 1,
      );
      if (custMaps.isNotEmpty) {
        final cust = custMaps.first;
        final grandTotal = (invoiceMap['grand_total'] as num).toDouble();
        final paid = (invoiceMap['paid_amount'] as num).toDouble();
        final pendingOnBill = (grandTotal - paid).clamp(0.0, double.infinity);

        final newTotal = ((cust['total_purchases'] as num).toDouble() - grandTotal)
            .clamp(0.0, double.infinity);
        final newPending = ((cust['pending_balance'] as num).toDouble() - pendingOnBill)
            .clamp(0.0, double.infinity);

        await txn.update(
          'customers',
          {
            'total_purchases': newTotal,
            'pending_balance': newPending,
          },
          where: 'id = ?',
          whereArgs: [cust['id']],
        );
      }
    });
  }

  /// Mark an invoice payment as complete or record partial payment
  Future<void> recordPayment(String invoiceId, double paymentAmount) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final invMaps = await txn.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
        limit: 1,
      );
      if (invMaps.isEmpty) throw Exception('Invoice not found');
      final inv = invMaps.first;
      final currentPaid = (inv['paid_amount'] as num).toDouble();
      final grandTotal = (inv['grand_total'] as num).toDouble();
      final newPaid = (currentPaid + paymentAmount).clamp(0.0, grandTotal);

      final newStatus = (newPaid >= grandTotal) ? 'Paid' : 'Partial';

      await txn.update(
        'invoices',
        {
          'paid_amount': newPaid,
          'payment_status': newStatus,
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // Adjust customer pending balance
      final phone = inv['customer_phone'] as String;
      final custMaps = await txn.query(
        'customers',
        where: 'phone = ?',
        whereArgs: [phone],
        limit: 1,
      );
      if (custMaps.isNotEmpty) {
        final cust = custMaps.first;
        final currentPending = (cust['pending_balance'] as num).toDouble();
        final newPending = (currentPending - paymentAmount).clamp(0.0, double.infinity);
        await txn.update(
          'customers',
          {'pending_balance': newPending},
          where: 'id = ?',
          whereArgs: [cust['id']],
        );
      }
    });
  }
}
