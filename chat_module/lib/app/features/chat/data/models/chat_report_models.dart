class ChatReportCategoryModel {
  const ChatReportCategoryModel({
    required this.id,
    required this.name,
    required this.description,
  });

  final int id;
  final String name;
  final String description;

  factory ChatReportCategoryModel.fromJson(Map<String, dynamic> json) {
    return ChatReportCategoryModel(
      id: _parseInt(json['category_id'] ?? json['id'] ?? json['category'] ?? 0),
      name: json['category_name']?.toString().trim() ?? '',
      description: json['category_description']?.toString().trim() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ChatReportCategoriesResponse {
  const ChatReportCategoriesResponse({required this.items});

  final List<ChatReportCategoryModel> items;

  factory ChatReportCategoriesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawItems = data is Map<String, dynamic> ? data['items'] : null;
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => ChatReportCategoryModel.fromJson(
                  item.cast<String, dynamic>(),
                ),
              )
              .where((item) => item.id > 0 && item.name.isNotEmpty)
              .toList()
        : const <ChatReportCategoryModel>[];
    return ChatReportCategoriesResponse(items: items);
  }
}
