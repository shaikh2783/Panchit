class ChatContactsResponse {
  const ChatContactsResponse({
    required this.implemented,
    required this.scaffoldOnly,
    required this.message,
    required this.contacts,
  });

  final bool implemented;
  final bool scaffoldOnly;
  final String message;
  final List<ChatContactModel> contacts;

  bool get isReady => implemented && !scaffoldOnly;

  factory ChatContactsResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawItems =
        (data['items'] as List?) ??
        (data['contacts'] as List?) ??
        (data['friends'] as List?) ??
        const [];

    return ChatContactsResponse(
      implemented: _parseBool(data['implemented'] ?? true),
      scaffoldOnly: _parseBool(data['scaffold_only']),
      message: json['message']?.toString() ?? '',
      contacts: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                ChatContactModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
}

class ChatContactModel {
  const ChatContactModel({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.avatarUrl,
    required this.isVerified,
    required this.isOnline,
    required this.lastSeen,
    required this.canMessage,
    required this.conversationId,
  });

  final int id;
  final String userName;
  final String fullName;
  final String avatarUrl;
  final bool isVerified;
  final bool isOnline;
  final String lastSeen;
  final bool canMessage;
  final int conversationId;

  String get title {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    return userName.trim();
  }

  factory ChatContactModel.fromJson(Map<String, dynamic> json) {
    return ChatContactModel(
      id: _parseInt(json['user_id'] ?? json['id']),
      userName: json['user_name']?.toString() ?? '',
      fullName:
          json['user_fullname']?.toString() ??
          [
            json['user_firstname']?.toString() ?? '',
            json['user_lastname']?.toString() ?? '',
          ].where((part) => part.trim().isNotEmpty).join(' ').trim(),
      avatarUrl:
          json['user_picture']?.toString() ?? json['picture']?.toString() ?? '',
      isVerified: _parseBool(
        json['user_verified'] ?? json['verified'] ?? json['is_verified'],
      ),
      isOnline: _parseBool(
        json['user_is_online'] ?? json['is_online'] ?? json['online'],
      ),
      lastSeen:
          json['user_last_seen_ago']?.toString() ??
          json['user_last_seen']?.toString() ??
          '',
      canMessage: _parseBool(json['can_message'] ?? true),
      conversationId: _parseInt(
        json['conversation_id'] ?? json['existing_conversation_id'],
      ),
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
