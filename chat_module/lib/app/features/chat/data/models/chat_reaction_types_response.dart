class ChatReactionTypesResponse {
  const ChatReactionTypesResponse({required this.types});

  final List<ChatReactionTypeModel> types;

  factory ChatReactionTypesResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawItems =
        (data['types'] as List?) ??
        (data['items'] as List?) ??
        (data['reactions'] as List?) ??
        const [];

    final types =
        rawItems
            .whereType<Map>()
            .map((item) => ChatReactionTypeModel.fromJson(item))
            .where((item) => item.enabled && item.key.isNotEmpty)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return ChatReactionTypesResponse(types: types);
  }
}

class ChatReactionTypeModel {
  const ChatReactionTypeModel({
    required this.key,
    required this.label,
    required this.emoji,
    required this.iconUrl,
    required this.order,
    required this.enabled,
  });

  final String key;
  final String label;
  final String emoji;
  final String iconUrl;
  final int order;
  final bool enabled;

  bool get hasIconUrl => iconUrl.trim().isNotEmpty;
  bool get hasEmoji => emoji.trim().isNotEmpty;

  factory ChatReactionTypeModel.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return ChatReactionTypeModel(
      key:
          map['reaction']?.toString() ??
          map['key']?.toString() ??
          map['name']?.toString() ??
          '',
      label:
          map['title']?.toString() ??
          map['label']?.toString() ??
          map['text']?.toString() ??
          map['name']?.toString() ??
          map['reaction']?.toString() ??
          '',
      emoji:
          map['emoji']?.toString() ??
          map['unicode']?.toString() ??
          map['icon_text']?.toString() ??
          '',
      iconUrl: map['image_url']?.toString() ?? map['image']?.toString() ?? '',
      order: int.tryParse(map['order']?.toString() ?? '') ?? 0,
      enabled: map['enabled'] == true || map['enabled']?.toString() == '1',
    );
  }
}
