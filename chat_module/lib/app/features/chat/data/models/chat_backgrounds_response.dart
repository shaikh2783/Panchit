import '../../../../../api_config.dart';

class ChatBackgroundsResponse {
  const ChatBackgroundsResponse({
    required this.items,
    required this.images,
    required this.colors,
    required this.presets,
  });

  final List<ChatBackgroundModel> items;
  final List<ChatBackgroundModel> images;
  final List<ChatBackgroundModel> colors;
  final List<ChatBackgroundModel> presets;

  factory ChatBackgroundsResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final grouped = (data['grouped'] as Map<String, dynamic>?) ?? const {};
    return ChatBackgroundsResponse(
      items: _parseBackgroundList(data['items']),
      images: _parseBackgroundList(grouped['images']),
      colors: _parseBackgroundList(grouped['colors']),
      presets: _parseBackgroundList(grouped['presets']),
    );
  }
}

class ChatConversationBackgroundResponse {
  const ChatConversationBackgroundResponse({
    required this.conversationId,
    required this.background,
  });

  final int conversationId;
  final ChatBackgroundModel? background;

  factory ChatConversationBackgroundResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawBackground = data['background'];
    return ChatConversationBackgroundResponse(
      conversationId: _parseInt(data['conversation_id']),
      background: _parseBackgroundObject(
        rawBackground ?? _extractNestedBackground(data),
      ),
    );
  }
}

class ChatBackgroundSaveResponse {
  const ChatBackgroundSaveResponse({
    required this.conversationId,
    required this.background,
  });

  final int conversationId;
  final ChatBackgroundModel? background;

  factory ChatBackgroundSaveResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawBackground = data['background'];
    return ChatBackgroundSaveResponse(
      conversationId: _parseInt(data['conversation_id']),
      background: _parseBackgroundObject(
        rawBackground ?? _extractNestedBackground(data),
      ),
    );
  }
}

class ChatBackgroundModel {
  const ChatBackgroundModel({
    required this.id,
    required this.title,
    required this.type,
    required this.value,
    required this.preview,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String type;
  final String value;
  final String preview;
  final bool isActive;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  bool get isColor => type == 'color';
  bool get isGradient => type == 'gradient';
  bool get isImage => type == 'image' || type == 'preset';
  bool get isSvg {
    final candidate = resolvedPreview;
    final path =
        Uri.tryParse(candidate)?.path.toLowerCase() ?? candidate.toLowerCase();
    return path.endsWith('.svg');
  }

  bool get hasPreviewUrl {
    final candidate = resolvedPreview;
    final uri = Uri.tryParse(candidate);
    return uri != null && uri.hasScheme;
  }

  List<String> get gradientStops {
    if (!isGradient) {
      return const <String>[];
    }
    return value
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String get resolvedPreview =>
      preview.trim().isNotEmpty ? preview.trim() : value.trim();

  factory ChatBackgroundModel.fromJson(Map<String, dynamic> json) {
    return ChatBackgroundModel(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString().trim().toLowerCase() ?? '',
      value: _normalizeAssetUrl(json['value']),
      preview: _normalizeAssetUrl(json['preview']),
      isActive: _parseBool(json['is_active'] ?? true),
      sortOrder: _parseInt(json['sort_order']),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

dynamic _extractNestedBackground(Map<String, dynamic> data) {
  final preferences = data['preferences'];
  if (preferences is Map && preferences['background'] != null) {
    return preferences['background'];
  }
  final conversation = data['conversation'];
  if (conversation is Map) {
    final conversationPreferences = conversation['preferences'];
    if (conversationPreferences is Map &&
        conversationPreferences['background'] != null) {
      return conversationPreferences['background'];
    }
    return conversation['background'];
  }
  return null;
}

ChatBackgroundModel? _parseBackgroundObject(dynamic rawBackground) {
  if (rawBackground is! Map) {
    return null;
  }
  final mapped = Map<String, dynamic>.from(rawBackground);
  final type = mapped['type']?.toString().trim() ?? '';
  final value = mapped['value']?.toString().trim() ?? '';
  final preview = mapped['preview']?.toString().trim() ?? '';
  if (type.isEmpty && value.isEmpty && preview.isEmpty) {
    return null;
  }
  return ChatBackgroundModel.fromJson(mapped);
}

List<ChatBackgroundModel> _parseBackgroundList(dynamic raw) {
  if (raw is! List) {
    return const <ChatBackgroundModel>[];
  }
  return raw
      .whereType<Map>()
      .map(
        (item) => ChatBackgroundModel.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList();
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

String _normalizeAssetUrl(dynamic value) {
  if (value == null) {
    return '';
  }
  final raw = value.toString().trim();
  if (raw.isEmpty || raw.toLowerCase() == 'null') {
    return '';
  }
  if (raw.startsWith('#') || raw.contains('|')) {
    return raw;
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  if (raw.startsWith('/')) {
    return '${ApiConfig.baseUrl}$raw';
  }
  if (raw.startsWith('api-addon-messangr/')) {
    return '${ApiConfig.baseUrl}/$raw';
  }
  return raw;
}
