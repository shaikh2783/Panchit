class Story {
  Story({
    required this.id,
    required this.authorName,
    this.authorId,
    this.authorAvatarUrl,
    this.items = const [],
    this.isOwner = false,
    this.isCommentEnabled = true,
    this.isReactionEnabled = true,
  });

  final String id;
  final String authorName;
  final String? authorId;
  final String? authorAvatarUrl;
  final List<StoryItem> items;
  final bool isOwner;
  final bool isCommentEnabled;
  final bool isReactionEnabled;

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: _string(json['id']) ?? '',
      authorName: _string(json['name']) ?? 'مستخدم',
      authorId: _string(json['user_id']),
      authorAvatarUrl: _string(json['photo']),
      items: (json['items'] as List?)
              ?.map((item) => StoryItem.fromJson(item))
              .toList() ??
          const [],
      isOwner:
          json['is_user'] == true || json['is_user'] == 1 || json['is_user'] == '1',
      isCommentEnabled: _bool(json['is_comment_enable']),
      isReactionEnabled: _bool(json['is_reaction_enable']),
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

  static bool _bool(Object? value) {
    if (value == null) {
      return true;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value.toString().toLowerCase();
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return true;
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
