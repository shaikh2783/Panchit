class Story {
  Story({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    this.items = const [],
  });

  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final List<StoryItem> items;

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: _string(json['id']) ?? '',
      authorName: _string(json['name']) ?? 'مستخدم',
      authorAvatarUrl: _string(json['photo']),
      items: (json['items'] as List?)
              ?.map((item) => StoryItem.fromJson(item))
              .toList() ??
          const [],
    );
  }

  static String? _string(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }
}

class StoryItem {
  StoryItem({
    required this.id,
    required this.type,
    required this.source,
    this.linkText = '',
  });

  final String id;
  final String type; // 'photo' or 'video'
  final String source;
  final String linkText;

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: Story._string(json['id']) ?? '',
      type: Story._string(json['type']) ?? 'photo',
      source: Story._string(json['src']) ?? '',
      linkText: Story._string(json['linkText']) ?? '',
    );
  }
}
