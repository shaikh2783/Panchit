import '../../../../../api_config.dart';

class ChatSharedContentResponse {
  const ChatSharedContentResponse({
    required this.conversationId,
    required this.items,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
    required this.counts,
  });

  final int conversationId;
  final List<ChatSharedItemModel> items;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;
  final ChatSharedCountsModel counts;

  factory ChatSharedContentResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawItems = (data['items'] as List?) ?? const [];

    return ChatSharedContentResponse(
      conversationId: _parseInt(data['conversation_id']),
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                ChatSharedItemModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: data['next_offset'] == null
          ? null
          : _parseInt(data['next_offset']),
      hasMore: _parseBool(data['has_more']),
      counts: ChatSharedCountsModel.fromJson(
        (data['counts'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class ChatSharedItemModel {
  const ChatSharedItemModel({
    required this.id,
    required this.messageId,
    required this.conversationId,
    required this.type,
    required this.message,
    required this.source,
    required this.url,
    required this.file,
    required this.thumbnail,
    required this.mediaUrl,
    required this.createdAt,
    required this.timeAgo,
    required this.postId,
    required this.reelId,
    required this.title,
    required this.sender,
  });

  final int id;
  final int messageId;
  final int conversationId;
  final String type;
  final String message;
  final String source;
  final String url;
  final String file;
  final String thumbnail;
  final String mediaUrl;
  final String createdAt;
  final String timeAgo;
  final int postId;
  final int reelId;
  final String title;
  final ChatSharedSenderModel? sender;

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';
  bool get isFile => type == 'file';
  bool get isLink => type == 'link';
  bool get isPost => type == 'post';
  bool get isReel => type == 'reel';

  String get bestUrl {
    for (final value in <String>[url, mediaUrl, file, source, thumbnail]) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  factory ChatSharedItemModel.fromJson(Map<String, dynamic> json) {
    return ChatSharedItemModel(
      id: _parseInt(json['id']),
      messageId: _parseInt(json['message_id']),
      conversationId: _parseInt(json['conversation_id']),
      type: json['type']?.toString().trim().toLowerCase() ?? '',
      message: json['message']?.toString() ?? '',
      source: _normalizeSharedAssetUrl(json['source']),
      url: _normalizeSharedAssetUrl(json['url']),
      file: _normalizeSharedAssetUrl(json['file']),
      thumbnail: _normalizeSharedAssetUrl(json['thumbnail']),
      mediaUrl: _normalizeSharedAssetUrl(json['media_url']),
      createdAt: json['created_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      postId: _parseInt(json['post_id']),
      reelId: _parseInt(json['reel_id']),
      title: json['title']?.toString() ?? '',
      sender: json['sender'] is Map
          ? ChatSharedSenderModel.fromJson(
              Map<String, dynamic>.from(json['sender'] as Map),
            )
          : null,
    );
  }
}

class ChatSharedSenderModel {
  const ChatSharedSenderModel({
    required this.userId,
    required this.userName,
    required this.fullName,
    required this.picture,
  });

  final int userId;
  final String userName;
  final String fullName;
  final String picture;

  factory ChatSharedSenderModel.fromJson(Map<String, dynamic> json) {
    return ChatSharedSenderModel(
      userId: _parseInt(json['user_id']),
      userName: json['user_name']?.toString() ?? '',
      fullName: json['user_fullname']?.toString() ?? '',
      picture: json['user_picture']?.toString() ?? '',
    );
  }
}

class ChatSharedCountsModel {
  const ChatSharedCountsModel({
    required this.images,
    required this.videos,
    required this.audio,
    required this.files,
    required this.links,
  });

  final int images;
  final int videos;
  final int audio;
  final int files;
  final int links;

  int countFor(String type) {
    switch (type) {
      case 'image':
        return images;
      case 'video':
        return videos;
      case 'audio':
        return audio;
      case 'file':
        return files;
      case 'link':
        return links;
      default:
        return images + videos + audio + files + links;
    }
  }

  factory ChatSharedCountsModel.fromJson(Map<String, dynamic> json) {
    return ChatSharedCountsModel(
      images: _parseInt(json['images']),
      videos: _parseInt(json['videos']),
      audio: _parseInt(json['audio']),
      files: _parseInt(json['files']),
      links: _parseInt(json['links']),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true';
}

String _normalizeSharedAssetUrl(dynamic value) {
  if (value == null) {
    return '';
  }
  final raw = value.toString().trim();
  if (raw.isEmpty || raw.toLowerCase() == 'null') {
    return '';
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  if (raw.startsWith('/')) {
    return '${ApiConfig.baseUrl}$raw';
  }
  if (raw.startsWith('photos/') ||
      raw.startsWith('videos/') ||
      raw.startsWith('sounds/')) {
    return _resolveSharedUploadUrl(raw);
  }
  return raw;
}

String _resolveSharedUploadUrl(String raw) {
  final trimmedBaseUrl = ApiConfig.baseUrl.trim().replaceFirst(
    RegExp(r'/+$'),
    '',
  );
  return '$trimmedBaseUrl/content/uploads/${raw.replaceFirst(RegExp(r'^/+'), '')}';
}
