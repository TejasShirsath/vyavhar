class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double purchasePrice; // Weighted average cost
  final double sellingPrice;
  final double currentStock;
  final String unit; // kg, g, box, packet, piece, etc.
  final double minStockAlert;
  final String? supplierName;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentStock,
    this.unit = 'piece',
    this.minStockAlert = 5.0,
    this.supplierName,
    this.imagePath,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOutOfStock => currentStock <= 0;
  bool get isLowStock => currentStock > 0 && currentStock <= minStockAlert;
  double get stockValue => currentStock * purchasePrice;
  double get profitMargin =>
      sellingPrice > 0 ? ((sellingPrice - purchasePrice) / sellingPrice) * 100 : 0.0;

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    double? currentStock,
    String? unit,
    double? minStockAlert,
    String? supplierName,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      supplierName: supplierName ?? this.supplierName,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'current_stock': currentStock,
      'unit': unit,
      'min_stock_alert': minStockAlert,
      'supplier_name': supplierName,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      sku: map['sku'] as String,
      category: map['category'] as String,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      currentStock: (map['current_stock'] as num).toDouble(),
      unit: (map['unit'] as String?) ?? 'piece',
      minStockAlert: (map['min_stock_alert'] as num?)?.toDouble() ?? 5.0,
      supplierName: map['supplier_name'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
