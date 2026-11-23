class WastageRecord {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final double unitCost; // Valued at purchase cost, not selling price
  final double totalLoss; // quantity * unitCost
  final String reason; // 'Expired', 'Damaged', 'Spoiled', 'Broken', 'Other'
  final String? notes;
  final DateTime createdAt;

  WastageRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unit = 'piece',
    required this.unitCost,
    required this.totalLoss,
    required this.reason,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'unit_cost': unitCost,
      'total_loss': totalLoss,
      'reason': reason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WastageRecord.fromMap(Map<String, dynamic> map) {
    return WastageRecord(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'piece',
      unitCost: (map['unit_cost'] as num).toDouble(),
      totalLoss: (map['total_loss'] as num).toDouble(),
      reason: map['reason'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
