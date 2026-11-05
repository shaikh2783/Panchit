import 'story_media_model.dart';

class StoryGroupModel {
  const StoryGroupModel({
    required this.id,
    required this.userId,
    required this.ownerUserId,
    required this.photo,
    required this.name,
    required this.lastUpdated,
    required this.items,
  });

  final String id;
  final int userId;
  final int ownerUserId;
  final String photo;
  final String name;
  final int lastUpdated;
  final List<StoryMediaModel> items;

  StoryMediaModel? get firstItem => items.isEmpty ? null : items.first;

  factory StoryGroupModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? const <dynamic>[]);
    final author = (json['author'] as Map<String, dynamic>?) ?? const {};

    return StoryGroupModel(
      id: json['id']?.toString() ?? '',
      userId: _parseInt(author['user_id'] ?? json['user_id']),
      ownerUserId: _parseInt(json['owner_user_id'] ?? author['user_id']),
      photo: author['photo']?.toString() ?? json['photo']?.toString() ?? '',
      name:
          author['name']?.toString().trim() ??
          json['name']?.toString().trim() ??
          '',
      lastUpdated: _parseInt(json['lastUpdated']),
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => StoryMediaModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
