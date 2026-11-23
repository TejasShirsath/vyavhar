import 'package:flutter_test/flutter_test.dart';
import 'package:vyavhar/core/utils/currency_formatter.dart';
import 'package:vyavhar/core/utils/date_formatter.dart';
import 'package:vyavhar/core/utils/id_generator.dart';
import 'package:vyavhar/models/invoice.dart';
import 'package:vyavhar/models/invoice_item.dart';
import 'package:vyavhar/models/product.dart';

void main() {
  group('VYAVHAR Business Logic Tests', () {
    test('Weighted Average Purchase Cost (WAC) calculation', () {
      const initialStock = 20.0;
      const initialCost = 100.0; // ₹2,000 value

      const purchasedQty = 10.0;
      const purchaseRate = 130.0; // ₹1,300 value

      final newStock = initialStock + purchasedQty;
      final newCost = ((initialStock * initialCost) + (purchasedQty * purchaseRate)) / newStock;

      expect(newStock, 30.0);
      expect(newCost, 110.0); // (2000 + 1300) / 30 = 3300 / 30 = 110.0
    });

    test('Stock valuation strictly at purchase cost, not selling price', () {
      final product = Product(
        id: 'p1',
        name: 'Kaju Katli',
        sku: 'VYV-1001',
        category: 'Snacks',
        purchasePrice: 650.0,
        sellingPrice: 850.0,
        currentStock: 24.0,
        createdAt: DateTime.now(),
      );

      // Stock valuation must be 24 * 650 = 15,600 (NOT 24 * 850 = 20,400)
      expect(product.stockValue, 15600.0);
      expect(product.isOutOfStock, false);
      expect(product.isLowStock, false);
    });

    test('Stock alert status tests (Low stock & Out of stock)', () {
      final lowStockProduct = Product(
        id: 'p2',
        name: 'Malpua Mix',
        sku: 'VYV-1006',
        category: 'Raw Material',
        purchasePrice: 140.0,
        sellingPrice: 210.0,
        currentStock: 6.0,
        minStockAlert: 10.0,
        createdAt: DateTime.now(),
      );

      expect(lowStockProduct.isLowStock, true);
      expect(lowStockProduct.isOutOfStock, false);

      final outOfStockProduct = lowStockProduct.copyWith(currentStock: 0.0);
      expect(outOfStockProduct.isOutOfStock, true);
      expect(outOfStockProduct.isLowStock, false);
    });

    test('Gross Profit and COGS calculation on Invoices', () {
      final item1 = InvoiceItem(
        id: 'i1',
        invoiceId: 'inv1',
        productId: 'p1',
        productName: 'Kaju Katli',
        sku: 'VYV-1001',
        unit: 'kg',
        quantity: 4.0,
        purchasePrice: 650.0,
        unitPrice: 850.0,
        totalAmount: 3400.0,
      );

      final item2 = InvoiceItem(
        id: 'i2',
        invoiceId: 'inv1',
        productId: 'p2',
        productName: 'Besan Laddu',
        sku: 'VYV-1002',
        unit: 'kg',
        quantity: 4.0,
        purchasePrice: 240.0,
        unitPrice: 350.0,
        totalAmount: 1400.0,
      );

      final invoice = Invoice(
        id: 'inv1',
        invoiceNumber: 'INV-1048',
        customerName: 'Naitik Traders',
        customerPhone: '+91 98231 12345',
        subtotal: 4800.0,
        grandTotal: 4800.0,
        paidAmount: 4800.0,
        createdAt: DateTime.now(),
        items: [item1, item2],
      );

      // COGS = (4 * 650) + (4 * 240) = 2600 + 960 = 3560
      expect(invoice.totalCogs, 3560.0);
      // Gross Profit = 4800 - 3560 = 1240
      expect(invoice.grossProfit, 1240.0);
      expect(invoice.pendingAmount, 0.0);
    });

    test('Partial Payment & Balance Due calculation', () {
      final invoice = Invoice(
        id: 'inv2',
        invoiceNumber: 'INV-1045',
        customerName: 'Ganesh Provisions',
        customerPhone: '+91 98450 11223',
        subtotal: 8130.0,
        grandTotal: 8130.0,
        paidAmount: 4630.0,
        paymentStatus: 'Partial',
        createdAt: DateTime.now(),
      );

      expect(invoice.pendingAmount, 3500.0);
    });

    test('Net Profit = Gross Profit - Operating Expenses - Wastage Loss', () {
      const grossProfit = 1240.0;
      const operatingExpenses = 400.0;
      const wastageLoss = 140.0;

      const netProfit = grossProfit - operatingExpenses - wastageLoss;
      expect(netProfit, 700.0);
    });

    test('Currency Formatter formats in Indian Rupees style', () {
      expect(CurrencyFormatter.format(24580), '₹24,580');
      expect(CurrencyFormatter.format(4800), '₹4,800');
      expect(CurrencyFormatter.formatCompact(150000), '₹1.5L');
    });

    test('Date Formatter formats DD/MM/YYYY and friendly dates', () {
      final dt = DateTime(2026, 11, 18, 10, 24);
      expect(DateFormatter.format(dt), '18/11/2026');
      expect(DateFormatter.formatTime(dt), '10:24 AM');
    });

    test('ID Generator creates standard SKU and Invoice numbers', () {
      expect(IdGenerator.sku(1), 'VYV-1001');
      expect(IdGenerator.sku(48), 'VYV-1048');
      expect(IdGenerator.invoiceNumber(48), 'INV-1048');
    });
  });
}
