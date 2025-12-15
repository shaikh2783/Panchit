import 'package:equatable/equatable.dart';
/// نموذج تصنيف الفعالية
class EventCategory extends Equatable {
  final int categoryId;
  final String categoryName;
  const EventCategory({
    required this.categoryId,
    required this.categoryName,
  });
  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      categoryId: int.parse(json['category_id'].toString()),
      categoryName: json['category_name']?.toString() ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
    };
  }
  @override
  List<Object?> get props => [categoryId, categoryName];
}
