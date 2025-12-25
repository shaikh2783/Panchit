/// نموذج فئة المجموعة
class GroupCategory {
  final int categoryId;
  final String categoryName;
  final String? categoryUrl;

  GroupCategory({
    required this.categoryId,
    required this.categoryName,
    this.categoryUrl,
  });

  factory GroupCategory.fromJson(Map<String, dynamic> json) {
    return GroupCategory(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      categoryUrl: json['category_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      if (categoryUrl != null) 'category_url': categoryUrl,
    };
  }
}
