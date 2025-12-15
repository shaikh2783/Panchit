class OfferCategory {
  final int id;
  final String title;
  OfferCategory({required this.id, required this.title});
  factory OfferCategory.fromJson(Map<String, dynamic> json) => OfferCategory(
        id: int.tryParse(json['category_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
        title: json['category_name']?.toString() ?? json['category_title']?.toString() ?? json['title']?.toString() ?? '',
      );
}
