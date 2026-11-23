class InvoiceItem {
  final String id;
  final String invoiceId;
  final String productId;
  final String productName;
  final String sku;
  final String unit;
  final double quantity;
  final double purchasePrice; // Cost of product at sale time for accurate COGS
  final double unitPrice; // Selling rate per unit
  final double totalAmount;

  InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unit,
    required this.quantity,
    required this.purchasePrice,
    required this.unitPrice,
    required this.totalAmount,
  });

  double get costOfGoodsSold => quantity * purchasePrice;
  double get profit => totalAmount - costOfGoodsSold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'unit': unit,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      sku: map['sku'] as String,
      unit: map['unit'] as String? ?? 'piece',
      quantity: (map['quantity'] as num).toDouble(),
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
    );
  }
}
