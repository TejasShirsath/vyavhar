class Category {
  final String id;
  final String name;
  final String? iconName;

  Category({
    required this.id,
    required this.name,
    this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['icon_name'] as String?,
    );
  }
}
