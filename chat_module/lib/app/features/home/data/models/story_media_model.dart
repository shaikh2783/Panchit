class StoryMediaModel {
  const StoryMediaModel({
    required this.id,
    required this.storyId,
    required this.storyMediaId,
    required this.ownerUserId,
    required this.type,
    required this.mediaType,
    required this.mimeType,
    required this.url,
    required this.src,
    required this.preview,
    required this.previewUrl,
    required this.link,
    required this.linkText,
    required this.text,
    required this.time,
    required this.timeAgo,
    required this.lengthSeconds,
    required this.viewsCount,
    required this.reactionsCount,
    required this.currentUserViewed,
    required this.currentUserReaction,
  });

  final String id;
  final int storyId;
  final int storyMediaId;
  final int ownerUserId;
  final String type;
  final String mediaType;
  final String mimeType;
  final String url;
  final String src;
  final String preview;
  final String previewUrl;
  final String link;
  final String linkText;
  final String text;
  final int time;
  final String timeAgo;
  final int lengthSeconds;
  final int viewsCount;
  final int reactionsCount;
  final bool currentUserViewed;
  final String currentUserReaction;

  String get displayImageUrl {
    if (previewUrl.trim().isNotEmpty) {
      return previewUrl.trim();
    }
    if (preview.trim().isNotEmpty) {
      return preview.trim();
    }
    if (url.trim().isNotEmpty) {
      return url.trim();
    }
    return src.trim();
  }

  bool get isVideo =>
      mediaType.toLowerCase() == 'video' || type.toLowerCase() == 'video';

  factory StoryMediaModel.fromJson(Map<String, dynamic> json) {
    return StoryMediaModel(
      id: json['id']?.toString() ?? '',
      storyId: _parseInt(json['story_id']),
      storyMediaId: _parseInt(json['story_media_id']),
      ownerUserId: _parseInt(json['owner_user_id']),
      type: json['type']?.toString() ?? 'photo',
      mediaType: json['media_type']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      src: json['src']?.toString() ?? '',
      preview: json['preview']?.toString() ?? '',
      previewUrl: json['preview_url']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      linkText: json['linkText']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      time: _parseInt(json['time']),
      timeAgo: json['time_ago']?.toString() ?? '',
      lengthSeconds: _parseInt(json['length']),
      viewsCount: _parseInt(json['views_count']),
      reactionsCount: _parseInt(json['reactions_count']),
      currentUserViewed: _parseBool(json['current_user_viewed']),
      currentUserReaction: json['current_user_reaction']?.toString() ?? '',
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
