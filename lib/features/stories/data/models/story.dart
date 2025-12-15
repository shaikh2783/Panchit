class Story {
  Story({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    this.previewImageUrl,
    List<StoryMedia>? media,
    this.isOwner = false,
    this.timestamp,
    this.isSeen = false,
  }) : media = media ?? const <StoryMedia>[];
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String? previewImageUrl;
  final List<StoryMedia> media;
  final bool isOwner;
  final DateTime? timestamp;
  final bool isSeen;
  bool get hasMedia => media.isNotEmpty;
  String? get effectivePreview {
    if (previewImageUrl != null && previewImageUrl!.isNotEmpty) {
      return previewImageUrl;
    }
    if (media.isNotEmpty) {
      return media.first.previewUrl ?? media.first.source;
    }
    return null;
  }
  Story copyWith({
    String? id,
    String? authorName,
    String? authorAvatarUrl,
    String? previewImageUrl,
    List<StoryMedia>? media,
    bool? isOwner,
    DateTime? timestamp,
    bool? isSeen,
  }) {
    return Story(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      media: media ?? this.media,
      isOwner: isOwner ?? this.isOwner,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
    );
  }
  factory Story.fromJson(Map<String, dynamic> json) {
    final id = _string(json['story_id']) ??
        _string(json['id']) ??
        _string(json['storyId']) ??
        _string(json['storyid']) ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final publisher = _map(json['publisher']) ?? _map(json['user']);
    final authorName = _resolveAuthorName(json, publisher);
    final authorAvatar =
        _string(json['photo']) ??
        _resolveAuthorAvatar(json, publisher) ??
        _string(json['avatar']);
    final mediaItems = <StoryMedia>[];
    void addMedia(Object? value) {
      if (value is Iterable) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            mediaItems.add(StoryMedia.fromJson(item));
          }
        }
      } else if (value is Map<String, dynamic>) {
        mediaItems.add(StoryMedia.fromJson(value));
      }
    }
    addMedia(json['media']);
    addMedia(json['story_media']);
    addMedia(json['items']);
    addMedia(json['stories']);
    addMedia(json['reels']); // Add support for reels array
    // Handle direct photo/video fields from API
    final photo = _string(json['photo']);
    if (photo != null && photo.isNotEmpty) {
      mediaItems.add(StoryMedia(
        id: '${id}_photo',
        type: 'photo',
        source: photo,
        previewUrl: photo,
      ));
    }
    final video = _string(json['video']);
    if (video != null && video.isNotEmpty) {
      mediaItems.add(StoryMedia(
        id: '${id}_video',
        type: 'video',
        source: video,
        thumbnail: photo, // Use photo as thumbnail for video
        previewUrl: photo ?? video,
      ));
    }
    final preview = _string(json['thumbnail']) ??
        _string(json['background']) ??
        (mediaItems.isNotEmpty ? mediaItems.first.previewUrl : null);
    final timestamp = _parseDate(json['time']) ?? _parseDate(json['date']);
    final isOwner = _bool(json['is_user'] ?? json['is_owner']);
    final isSeen = _bool(json['is_seen'] ?? json['seen']);
    return Story(
      id: id,
      authorName: authorName,
      authorAvatarUrl: authorAvatar,
      previewImageUrl: preview,
      media: mediaItems.where((item) => item.isValid).toList(),
      isOwner: isOwner,
      timestamp: timestamp,
      isSeen: isSeen,
    );
  }
  static String _resolveAuthorName(
    Map<String, dynamic> json,
    Map<String, dynamic>? publisher,
  ) {
    final candidates = [
      _string(json['story_author_name']),
      _string(json['user_fullname']),
      _string(json['user_name']),
      _string(json['owner_name']),
      _string(json['username']),
      _string(json['name']),
      _string(json['firstname']),
      _string(json['lastname']),
      if (publisher != null) _string(publisher['user_fullname']),
      if (publisher != null) _string(publisher['user_name']),
      if (publisher != null) _string(publisher['name']),
      if (publisher != null) _string(publisher['firstname']),
    ];
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return 'مستخدم';
  }
  static String? _resolveAuthorAvatar(
    Map<String, dynamic> json,
    Map<String, dynamic>? publisher,
  ) {
    final candidates = [
      _string(json['story_author_picture']),
      _string(json['user_avatar']),
      _string(json['user_picture']),
      _string(json['picture']),
      _string(json['image']),
      if (publisher != null) _string(publisher['user_picture']),
      if (publisher != null) _string(publisher['picture']),
      if (publisher != null) _string(publisher['user_avatar']),
      if (publisher != null) _string(publisher['avatar']),
    ];
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
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
  static Map<String, dynamic>? _map(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }
  static bool _bool(Object? value) {
    if (value == null) {
      return false;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value.toString().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'y';
  }
  static DateTime? _parseDate(Object? value) {
    final raw = _string(value);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed;
    }
    // Handle possible unix timestamps.
    final numeric = int.tryParse(raw);
    if (numeric != null) {
      if (raw.length == 13) {
        return DateTime.fromMillisecondsSinceEpoch(numeric);
      }
      if (raw.length == 10) {
        return DateTime.fromMillisecondsSinceEpoch(numeric * 1000);
      }
    }
    return null;
  }
}
class StoryMedia {
  StoryMedia({
    required this.id,
    required this.type,
    required this.source,
    this.thumbnail,
    this.previewUrl,
    this.duration,
  });
  final String id;
  final String type;
  final String source;
  final String? thumbnail;
  final String? previewUrl;
  final Duration? duration;
  bool get isVideo => type.toLowerCase() == 'video';
  bool get isValid => source.isNotEmpty;
  factory StoryMedia.fromJson(Map<String, dynamic> json) {
    final id = Story._string(json['id']) ??
        Story._string(json['media_id']) ??
        Story._string(json['story_media_id']) ??
        Story._string(json['story_id']) ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final type = (Story._string(json['type']) ??
            Story._string(json['media_type']) ??
            Story._string(json['story_type']) ??
            'photo')
        .toLowerCase();
    final source = Story._string(json['src']) ??
        Story._string(json['source']) ??
        Story._string(json['media']) ??
        Story._string(json['file']) ??
        Story._string(json['photo']) ??
        Story._string(json['video']) ??
        '';
    final thumbnail = Story._string(json['thumbnail']) ??
        Story._string(json['thumb']) ??
        Story._string(json['poster']) ??
        Story._string(json['photo']);
    final preview = Story._string(json['preview']) ?? thumbnail ?? source;
    // ✅ إصلاح: التعامل مع duration كـ int أو String
    Duration? duration;
    final durationValue = json['duration'] ?? json['length'];
    if (durationValue != null) {
      if (durationValue is int) {
        duration = Duration(seconds: durationValue);
      } else if (durationValue is double) {
        duration = Duration(milliseconds: (durationValue * 1000).round());
      } else if (durationValue is String) {
        final numeric = double.tryParse(durationValue);
        if (numeric != null) {
          duration = Duration(milliseconds: (numeric * 1000).round());
        }
      }
    }
    return StoryMedia(
      id: id,
      type: type,
      source: source,
      thumbnail: thumbnail,
      previewUrl: preview,
      duration: duration,
    );
  }
}
