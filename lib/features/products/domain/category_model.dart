class CategoryModel {
  final String id;
  final String name;
  final String? parentId;
  final int displayOrder;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.displayOrder = 0,
    required this.createdAt,
  });

  bool get isSubcategory => parentId != null;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'display_order': displayOrder,
    };
  }
}
