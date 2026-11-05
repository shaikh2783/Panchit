import 'story_group_model.dart';

class StoriesResponseModel {
  const StoriesResponseModel({
    required this.items,
    required this.count,
    required this.hasMyStory,
  });

  final List<StoryGroupModel> items;
  final int count;
  final bool hasMyStory;

  factory StoriesResponseModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawItems = (data['items'] as List<dynamic>? ?? const <dynamic>[]);

    return StoriesResponseModel(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => StoryGroupModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      count: _parseInt(data['count']),
      hasMyStory: _parseBool(data['has_my_story']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
}
