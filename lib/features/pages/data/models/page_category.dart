/// Model for page category
class PageCategory {
  final int categoryId;
  final String categoryName;
  final String? categoryDescription;

  PageCategory({
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription,
  });

  factory PageCategory.fromJson(Map<String, dynamic> json) {
    return PageCategory(
      categoryId: _parseInt(json['category_id']),
      categoryName: json['category_name']?.toString() ?? '',
      categoryDescription: json['category_description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      if (categoryDescription != null) 'category_description': categoryDescription,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() => 'PageCategory(id: $categoryId, name: $categoryName)';
}
