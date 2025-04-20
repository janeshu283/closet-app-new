class CatalogItem {
  final String id;
  final String name;
  final String brand;
  final String? category;
  final String? imageUrl;
  final bool isUserAdded;
  final DateTime createdAt;

  CatalogItem({
    required this.id,
    required this.name,
    required this.brand,
    this.category,
    this.imageUrl,
    this.isUserAdded = false,
    required this.createdAt,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      isUserAdded: json['is_user_added'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'image_url': imageUrl,
      'is_user_added': isUserAdded,
    };
  }
}
