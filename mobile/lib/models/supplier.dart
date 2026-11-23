class Supplier {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final double totalSupplied;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.totalSupplied = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'total_supplied': totalSupplied,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      totalSupplied: (map['total_supplied'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
