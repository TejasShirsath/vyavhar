class Customer {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? imagePath;
  final double totalPurchases;
  final double pendingBalance;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.imagePath,
    this.totalPurchases = 0.0,
    this.pendingBalance = 0.0,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? imagePath,
    double? totalPurchases,
    double? pendingBalance,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'image_path': imagePath,
      'total_purchases': totalPurchases,
      'pending_balance': pendingBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      imagePath: map['image_path'] as String?,
      totalPurchases: (map['total_purchases'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (map['pending_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
