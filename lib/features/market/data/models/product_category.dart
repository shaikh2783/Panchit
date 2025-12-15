import 'package:equatable/equatable.dart';
/// Product Category Model - فئة المنتج
class ProductCategory extends Equatable {
  final int categoryId;
  final String categoryName;
  final String categoryDescription;
  final int categoryOrder;
  const ProductCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryDescription,
    required this.categoryOrder,
  });
  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      categoryId: int.parse(json['category_id'].toString()),
      categoryName: json['category_name'].toString(),
      categoryDescription: json['category_description']?.toString() ?? '',
      categoryOrder: int.parse(json['category_order']?.toString() ?? '1'),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'category_description': categoryDescription,
      'category_order': categoryOrder,
    };
  }
  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryDescription,
        categoryOrder,
      ];
}
