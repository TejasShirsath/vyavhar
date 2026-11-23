class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String movementType; // 'PURCHASE', 'SALE', 'WASTAGE', 'RETURN', 'INITIAL'
  final double quantity;
  final double unitPrice;
  final double totalValue;
  final String? referenceId; // invoice_id, purchase_id, etc.
  final String? reason;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    this.productName = '',
    required this.movementType,
    required this.quantity,
    required this.unitPrice,
    required this.totalValue,
    this.referenceId,
    this.reason,
    required this.createdAt,
  });

  bool get isAddition => movementType == 'PURCHASE' || movementType == 'RETURN' || movementType == 'INITIAL';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'movement_type': movementType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_value': totalValue,
      'reference_id': referenceId,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map, {String productName = ''}) {
    return StockMovement(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: productName.isNotEmpty ? productName : (map['product_name'] as String? ?? ''),
      movementType: map['movement_type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalValue: (map['total_value'] as num).toDouble(),
      referenceId: map['reference_id'] as String?,
      reason: map['reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
