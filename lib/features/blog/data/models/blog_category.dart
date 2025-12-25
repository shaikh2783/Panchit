class BlogCategory {
  final int categoryId;
  final String categoryName;
  final int? categoryOrder;

  const BlogCategory({
    required this.categoryId,
    required this.categoryName,
    this.categoryOrder,
  });

  factory BlogCategory.fromJson(Map<String, dynamic> json) {
    return BlogCategory(
      categoryId: json['category_id'] is String
          ? int.tryParse(json['category_id']) ?? 0
          : (json['category_id'] ?? 0) as int,
      categoryName: (json['category_name'] ?? '').toString(),
      categoryOrder: json['category_order'] is String
          ? int.tryParse(json['category_order'])
          : json['category_order'] as int?,
    );
  }
}
