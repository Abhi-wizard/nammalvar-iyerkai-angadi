class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final String? subcategoryId;
  final String? brand;
  final String unit;
  final double sellingPrice;
  final double costPrice;
  final double currentStock;
  final double minimumStock;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined category names for display
  final String? categoryName;
  final String? subcategoryName;

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.subcategoryId,
    this.brand,
    required this.unit,
    required this.sellingPrice,
    this.costPrice = 0.0,
    this.currentStock = 0.0,
    this.minimumStock = 5.0,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.subcategoryName,
  });

  bool get isActive => status == 'active';
  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;
  double get estimatedProfit => sellingPrice - costPrice;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      subcategoryId: json['subcategory_id'] as String?,
      brand: json['brand'] as String?,
      unit: json['unit'] as String? ?? 'piece',
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      minimumStock: (json['minimum_stock'] as num?)?.toDouble() ?? 5.0,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
      categoryName: json['categories'] != null ? json['categories']['name'] as String? : null,
      subcategoryName: json['subcategories'] != null ? json['subcategories']['name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'brand': brand,
      'unit': unit,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'status': status,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? subcategoryId,
    String? brand,
    String? unit,
    double? sellingPrice,
    double? costPrice,
    double? currentStock,
    double? minimumStock,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? subcategoryName,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      subcategoryName: subcategoryName ?? this.subcategoryName,
    );
  }
}
