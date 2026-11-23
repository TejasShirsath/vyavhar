import '../core/database/app_database.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../models/wastage_record.dart';

enum DateRangeFilter {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  previousMonth,
  custom,
}

class DateRange {
  final DateTime start;
  final DateTime end;
  final String label;

  DateRange({required this.start, required this.end, required this.label});

  static DateRange fromFilter(DateRangeFilter filter, {DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (filter) {
      case DateRangeFilter.today:
        return DateRange(start: todayStart, end: todayEnd, label: 'Today');
      case DateRangeFilter.yesterday:
        final yStart = todayStart.subtract(const Duration(days: 1));
        final yEnd = DateTime(yStart.year, yStart.month, yStart.day, 23, 59, 59);
        return DateRange(start: yStart, end: yEnd, label: 'Yesterday');
      case DateRangeFilter.last7Days:
        final s7 = todayStart.subtract(const Duration(days: 6));
        return DateRange(start: s7, end: todayEnd, label: 'Last 7 Days');
      case DateRangeFilter.last30Days:
        final s30 = todayStart.subtract(const Duration(days: 29));
        return DateRange(start: s30, end: todayEnd, label: 'Last 30 Days');
      case DateRangeFilter.thisMonth:
        final mStart = DateTime(now.year, now.month, 1);
        return DateRange(start: mStart, end: todayEnd, label: 'This Month');
      case DateRangeFilter.previousMonth:
        final prevMonthLastDay = DateTime(now.year, now.month, 0);
        final prevMonthFirstDay = DateTime(prevMonthLastDay.year, prevMonthLastDay.month, 1);
        final prevMonthEnd = DateTime(
          prevMonthLastDay.year,
          prevMonthLastDay.month,
          prevMonthLastDay.day,
          23,
          59,
          59,
        );
        return DateRange(start: prevMonthFirstDay, end: prevMonthEnd, label: 'Previous Month');
      case DateRangeFilter.custom:
        return DateRange(
          start: customStart ?? todayStart.subtract(const Duration(days: 7)),
          end: customEnd ?? todayEnd,
          label: 'Custom Range',
        );
    }
  }
}

class StockValuationSummary {
  final double totalStockQuantity;
  final double totalStockValue; // at purchase cost
  final List<Product> products;
  final List<Product> topValueProducts;
  final List<Product> lowStockProducts;
  final List<Product> outOfStockProducts;

  StockValuationSummary({
    required this.totalStockQuantity,
    required this.totalStockValue,
    required this.products,
    required this.topValueProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
  });
}

class ProfitLossSummary {
  final double totalSalesRevenue;
  final double costOfGoodsSold;
  final double grossProfit;
  final double totalExpenses;
  final double wastageLoss;
  final double netProfit;
  final double profitMarginPercentage; // (Gross Profit / Sales Revenue) * 100
  final double netMarginPercentage; // (Net Profit / Sales Revenue) * 100

  ProfitLossSummary({
    required this.totalSalesRevenue,
    required this.costOfGoodsSold,
    required this.grossProfit,
    required this.totalExpenses,
    required this.wastageLoss,
    required this.netProfit,
    required this.profitMarginPercentage,
    required this.netMarginPercentage,
  });
}

class WastageSummary {
  final double totalWastedQuantity;
  final double totalWastageLoss; // At purchase cost
  final List<WastageRecord> records;
  final Map<String, double> lossByReason;
  final Map<String, double> lossByProduct;

  WastageSummary({
    required this.totalWastedQuantity,
    required this.totalWastageLoss,
    required this.records,
    required this.lossByReason,
    required this.lossByProduct,
  });
}

class SalesReportSummary {
  final double totalSalesAmount;
  final int totalInvoicesCount;
  final double totalQuantitySold;
  final List<Invoice> invoices;
  final Map<String, double> salesByDate;
  final List<Map<String, dynamic>> topProducts;
  final Map<String, double> customerSales;

  SalesReportSummary({
    required this.totalSalesAmount,
    required this.totalInvoicesCount,
    required this.totalQuantitySold,
    required this.invoices,
    required this.salesByDate,
    required this.topProducts,
    required this.customerSales,
  });
}

class ReportsService {
  final AppDatabase _db = AppDatabase.instance;

  // --- 1. Stock Valuation Report ---
  Future<StockValuationSummary> getStockValuationReport() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('products', orderBy: 'name ASC');
    final products = maps.map((m) => Product.fromMap(m)).toList();

    double totalQuantity = 0.0;
    double totalValue = 0.0;
    final List<Product> lowStock = [];
    final List<Product> outOfStock = [];

    for (final p in products) {
      totalQuantity += p.currentStock;
      totalValue += p.stockValue; // currentStock * purchasePrice

      if (p.isOutOfStock) {
        outOfStock.add(p);
      } else if (p.isLowStock) {
        lowStock.add(p);
      }
    }

    final sortedByValue = List<Product>.from(products)
      ..sort((a, b) => b.stockValue.compareTo(a.stockValue));

    return StockValuationSummary(
      totalStockQuantity: totalQuantity,
      totalStockValue: totalValue,
      products: products,
      topValueProducts: sortedByValue.take(5).toList(),
      lowStockProducts: lowStock,
      outOfStockProducts: outOfStock,
    );
  }

  // --- 2. Profit & Loss Report ---
  Future<ProfitLossSummary> getProfitLossReport(DateRange range) async {
    final db = await _db.database;
    final startIso = range.start.toIso8601String();
    final endIso = range.end.toIso8601String();

    // Query non-cancelled invoices in date range
    final List<Map<String, dynamic>> invMaps = await db.query(
      'invoices',
      where: 'created_at BETWEEN ? AND ? AND is_cancelled = 0',
      whereArgs: [startIso, endIso],
    );

    double totalRevenue = 0.0;
    double totalCogs = 0.0;

    for (final inv in invMaps) {
      final invId = inv['id'] as String;
      totalRevenue += (inv['grand_total'] as num).toDouble();

      final List<Map<String, dynamic>> itemMaps = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invId],
      );

      for (final item in itemMaps) {
        final qty = (item['quantity'] as num).toDouble();
        final cost = (item['purchase_price'] as num).toDouble();
        totalCogs += qty * cost;
      }
    }

    final grossProfit = totalRevenue - totalCogs;

    // Expenses in date range
    final expMaps = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date BETWEEN ? AND ?',
      [startIso, endIso],
    );
    final totalExpenses = (expMaps.first['total'] as num?)?.toDouble() ?? 0.0;

    // Wastage losses in date range
    final wasteMaps = await db.rawQuery(
      'SELECT SUM(total_loss) as total FROM wastage_records WHERE created_at BETWEEN ? AND ?',
      [startIso, endIso],
    );
    final wastageLoss = (wasteMaps.first['total'] as num?)?.toDouble() ?? 0.0;

    final netProfit = grossProfit - totalExpenses - wastageLoss;

    final grossMargin = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;
    final netMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

    return ProfitLossSummary(
      totalSalesRevenue: totalRevenue,
      costOfGoodsSold: totalCogs,
      grossProfit: grossProfit,
      totalExpenses: totalExpenses,
      wastageLoss: wastageLoss,
      netProfit: netProfit,
      profitMarginPercentage: grossMargin,
      netMarginPercentage: netMargin,
    );
  }

  // --- 3. Wastage Report ---
  Future<WastageSummary> getWastageReport(DateRange range) async {
    final db = await _db.database;
    final startIso = range.start.toIso8601String();
    final endIso = range.end.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'wastage_records',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startIso, endIso],
      orderBy: 'created_at DESC',
    );

    final records = maps.map((m) => WastageRecord.fromMap(m)).toList();
    double totalQty = 0.0;
    double totalLoss = 0.0;
    final Map<String, double> byReason = {};
    final Map<String, double> byProduct = {};

    for (final r in records) {
      totalQty += r.quantity;
      totalLoss += r.totalLoss;

      byReason[r.reason] = (byReason[r.reason] ?? 0.0) + r.totalLoss;
      byProduct[r.productName] = (byProduct[r.productName] ?? 0.0) + r.totalLoss;
    }

    return WastageSummary(
      totalWastedQuantity: totalQty,
      totalWastageLoss: totalLoss,
      records: records,
      lossByReason: byReason,
      lossByProduct: byProduct,
    );
  }

  // --- 4. Sales Report ---
  Future<SalesReportSummary> getSalesReport(DateRange range) async {
    final db = await _db.database;
    final startIso = range.start.toIso8601String();
    final endIso = range.end.toIso8601String();

    final List<Map<String, dynamic>> invMaps = await db.query(
      'invoices',
      where: 'created_at BETWEEN ? AND ? AND is_cancelled = 0',
      whereArgs: [startIso, endIso],
      orderBy: 'created_at ASC',
    );

    double totalAmount = 0.0;
    double totalQtySold = 0.0;
    final Map<String, double> salesByDate = {};
    final Map<String, double> customerSales = {};
    final Map<String, Map<String, dynamic>> productStats = {};
    final List<Invoice> invoices = [];

    for (final map in invMaps) {
      final inv = Invoice.fromMap(map);
      invoices.add(inv);
      totalAmount += inv.grandTotal;

      // Date bucket (yyyy-MM-dd)
      final dateKey = inv.createdAt.toIso8601String().substring(0, 10);
      salesByDate[dateKey] = (salesByDate[dateKey] ?? 0.0) + inv.grandTotal;

      // Customer bucket
      customerSales[inv.customerName] = (customerSales[inv.customerName] ?? 0.0) + inv.grandTotal;

      // Fetch items for product breakdown
      final itemMaps = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [inv.id],
      );

      for (final item in itemMaps) {
        final pName = item['product_name'] as String;
        final qty = (item['quantity'] as num).toDouble();
        final amt = (item['total_amount'] as num).toDouble();
        totalQtySold += qty;

        if (!productStats.containsKey(pName)) {
          productStats[pName] = {
            'name': pName,
            'quantity': 0.0,
            'revenue': 0.0,
            'unit': item['unit'] as String,
          };
        }
        productStats[pName]!['quantity'] = (productStats[pName]!['quantity'] as double) + qty;
        productStats[pName]!['revenue'] = (productStats[pName]!['revenue'] as double) + amt;
      }
    }

    final topProducts = productStats.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    return SalesReportSummary(
      totalSalesAmount: totalAmount,
      totalInvoicesCount: invoices.length,
      totalQuantitySold: totalQtySold,
      invoices: invoices,
      salesByDate: salesByDate,
      topProducts: topProducts,
      customerSales: customerSales,
    );
  }

  // --- 5. Expenses Report ---
  Future<Map<String, dynamic>> getExpensesReport(DateRange range) async {
    final db = await _db.database;
    final startIso = range.start.toIso8601String();
    final endIso = range.end.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startIso, endIso],
      orderBy: 'date DESC',
    );

    final expenses = maps.map((m) => Expense.fromMap(m)).toList();
    double total = 0.0;
    final Map<String, double> byCategory = {};

    for (final e in expenses) {
      total += e.amount;
      byCategory[e.category] = (byCategory[e.category] ?? 0.0) + e.amount;
    }

    return {
      'total': total,
      'expenses': expenses,
      'byCategory': byCategory,
    };
  }

  // --- Add New Expense ---
  Future<Expense> addExpense({
    required String title,
    required double amount,
    required String category,
    DateTime? date,
    String? notes,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final expenseDate = date ?? now;

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: category,
      date: expenseDate,
      notes: notes,
      createdAt: now,
    );

    await db.insert('expenses', expense.toMap());
    return expense;
  }
}
