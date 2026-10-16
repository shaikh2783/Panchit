import 'package:get/get.dart';

import '../../../../core/localization/app_translations.dart';

class ChatConversationsResponse {
  const ChatConversationsResponse({
    required this.implemented,
    required this.scaffoldOnly,
    required this.message,
    required this.endpoint,
    required this.conversations,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
  });

  final bool implemented;
  final bool scaffoldOnly;
  final String message;
  final String endpoint;
  final List<ChatConversationModel> conversations;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  bool get hasConversations => conversations.isNotEmpty;

  factory ChatConversationsResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawItems =
        (data['items'] as List?) ??
        (data['conversations'] as List?) ??
        (data['data'] as List?) ??
        const [];

    return ChatConversationsResponse(
      implemented: _parseBool(data['implemented'] ?? true),
      scaffoldOnly: _parseBool(data['scaffold_only']),
      message: json['message']?.toString() ?? '',
      endpoint: data['endpoint']?.toString() ?? '',
      conversations: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                ChatConversationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: _parseNullableInt(data['next_offset']),
      hasMore: _parseBool(data['has_more']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}

const _stickerMessagePlaceholder = '\u200B';

class ChatConversationModel {
  const ChatConversationModel({
    required this.id,
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.avatarUrl,
    required this.isOnline,
    required this.isTyping,
    required this.unreadCount,
    required this.isSeen,
    required this.isPinned,
    required this.isMuted,
    this.blockedByMe = false,
    this.blockedMe = false,
    this.canSendMessages = true,
    this.targetUserId = 0,
    this.nodeId = 0,
    this.nodeType = '',
    this.isGroupConversation = false,
  });

  final String id;
  final String title;
  final String preview;
  final String timeLabel;
  final String avatarUrl;
  final bool isOnline;
  final bool isTyping;
  final int unreadCount;
  final bool isSeen;
  final bool isPinned;
  final bool isMuted;
  final bool blockedByMe;
  final bool blockedMe;
  final bool canSendMessages;
  final int targetUserId;
  final int nodeId;
  final String nodeType;
  final bool isGroupConversation;

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final recipients =
        (json['recipients'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        const <Map<String, dynamic>>[];
    final firstRecipient = recipients.isNotEmpty ? recipients.first : null;
    final lastMessage = _asMap(json['last_message']);
    final seen = ChatConversationsResponse._parseBool(json['seen']);
    final typing = ChatConversationsResponse._parseBool(
      firstRecipient?['typing'] ?? json['is_typing'],
    );
    final unreadCount = seen
        ? 0
        : int.tryParse(
                json['unread_count']?.toString() ??
                    json['unread']?.toString() ??
                    '1',
              ) ??
              1;
    final rawPreview =
        lastMessage['message_decoded']?.toString() ??
        lastMessage['message']?.toString() ??
        json['preview']?.toString() ??
        json['message']?.toString() ??
        '';
    final sanitizedRawPreview = _sanitizePreview(rawPreview);
    final post = _asMap(lastMessage['post']);
    final product = _asMap(post['product']);
    final preferences = _asMap(json['preferences']);
    final relationship = _asMap(json['relationship']);

    return ChatConversationModel(
      id: json['id']?.toString() ?? json['conversation_id']?.toString() ?? '',
      title:
          json['title']?.toString() ??
          json['name']?.toString() ??
          json['name_list']?.toString() ??
          json['conversation_name']?.toString() ??
          '',
      preview: sanitizedRawPreview.isNotEmpty
          ? sanitizedRawPreview
          : _fallbackPreviewFromLastMessage(lastMessage, post, product),
      timeLabel:
          lastMessage['time_ago']?.toString() ??
          json['time_ago']?.toString() ??
          lastMessage['time']?.toString() ??
          json['time']?.toString() ??
          json['time_label']?.toString() ??
          json['last_message_time']?.toString() ??
          '',
      avatarUrl:
          json['picture']?.toString() ??
          json['avatar']?.toString() ??
          json['image']?.toString() ??
          firstRecipient?['user_picture']?.toString() ??
          '',
      isOnline: ChatConversationsResponse._parseBool(
        json['user_is_online'] ?? json['is_online'] ?? json['online'],
      ),
      isTyping: typing,
      unreadCount: unreadCount,
      isSeen: seen,
      isPinned: ChatConversationsResponse._parseBool(
        json['is_pinned'] ?? preferences['is_pinned'],
      ),
      isMuted: ChatConversationsResponse._parseBool(
        json['is_muted'] ?? preferences['is_muted'],
      ),
      blockedByMe: ChatConversationsResponse._parseBool(
        json['blocked_by_me'] ?? relationship['blocked_by_me'],
      ),
      blockedMe: ChatConversationsResponse._parseBool(
        json['blocked_me'] ?? relationship['blocked_me'],
      ),
      canSendMessages: ChatConversationsResponse._parseBool(
        json['can_send_messages'] ?? relationship['can_send_messages'] ?? true,
      ),
      targetUserId: _parseInt(
        json['user_id'] ??
            firstRecipient?['user_id'] ??
            firstRecipient?['id'] ??
            json['target_user_id'],
      ),
      nodeId: _parseInt(json['node_id']),
      nodeType: json['node_type']?.toString().trim().toLowerCase() ?? '',
      isGroupConversation:
          ChatConversationsResponse._parseBool(json['multiple_recipients']) ||
          json['node_type']?.toString().trim().toLowerCase() == 'group',
    );
  }

  ChatConversationModel copyWith({
    String? id,
    String? title,
    String? preview,
    String? timeLabel,
    String? avatarUrl,
    bool? isOnline,
    bool? isTyping,
    int? unreadCount,
    bool? isSeen,
    bool? isPinned,
    bool? isMuted,
    bool? blockedByMe,
    bool? blockedMe,
    bool? canSendMessages,
    int? targetUserId,
    int? nodeId,
    String? nodeType,
    bool? isGroupConversation,
  }) {
    return ChatConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      timeLabel: timeLabel ?? this.timeLabel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
      unreadCount: unreadCount ?? this.unreadCount,
      isSeen: isSeen ?? this.isSeen,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      blockedByMe: blockedByMe ?? this.blockedByMe,
      blockedMe: blockedMe ?? this.blockedMe,
      canSendMessages: canSendMessages ?? this.canSendMessages,
      targetUserId: targetUserId ?? this.targetUserId,
      nodeId: nodeId ?? this.nodeId,
      nodeType: nodeType ?? this.nodeType,
      isGroupConversation: isGroupConversation ?? this.isGroupConversation,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _sanitizePreview(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    return value
        .replaceAll(_stickerMessagePlaceholder, '')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _fallbackPreviewFromLastMessage(
    Map<String, dynamic> lastMessage,
    Map<String, dynamic> post,
    Map<String, dynamic> product,
  ) {
    final messageType =
        lastMessage['message_type']?.toString().trim().toLowerCase() ?? '';
    final sharedItem = _asMap(lastMessage['shared_item']);
    if (messageType == 'shared_post' || messageType == 'shared_reel') {
      final title =
          sharedItem['title']?.toString().trim() ??
          sharedItem['caption']?.toString().trim() ??
          sharedItem['text']?.toString().trim() ??
          '';
      if (title.isNotEmpty) {
        return title;
      }
      return messageType == 'shared_reel'
          ? AppTranslations.sharedReel.tr
          : AppTranslations.sharedPost.tr;
    }
    if ((product['name']?.toString() ?? '').trim().isNotEmpty) {
      return product['name']!.toString();
    }
    if ((post['og_title']?.toString() ?? '').trim().isNotEmpty) {
      return post['og_title']!.toString();
    }
    if ((lastMessage['voice_note']?.toString() ?? '').trim().isNotEmpty) {
      return AppTranslations.homeStatusVoice.tr;
    }
    final location = lastMessage['location'];
    if (messageType == 'location' ||
        location is Map ||
        (lastMessage['latitude']?.toString().trim().isNotEmpty ?? false)) {
      return AppTranslations.commonLocation.tr;
    }
    final contact = lastMessage['contact'];
    if (messageType == 'contact' ||
        contact is Map ||
        (lastMessage['phone_number']?.toString().trim().isNotEmpty ?? false)) {
      return AppTranslations.commonContact.tr;
    }
    if ((lastMessage['sticker']?.toString() ?? '').trim().isNotEmpty ||
        (lastMessage['sticker_url']?.toString() ?? '').trim().isNotEmpty ||
        (lastMessage['sticker_image']?.toString() ?? '').trim().isNotEmpty ||
        ((lastMessage['sticker_id']?.toString() ?? '').trim().isNotEmpty &&
            lastMessage['sticker_id']?.toString() != '0')) {
      return AppTranslations.commonSticker.tr;
    }
    if ((lastMessage['video']?.toString() ?? '').trim().isNotEmpty) {
      return AppTranslations.commonVideo.tr;
    }
    if ((lastMessage['image']?.toString() ?? '').trim().isNotEmpty) {
      return AppTranslations.commonImage.tr;
    }
    return '';
  }
}

Map<String, dynamic> _asMap(
  dynamic value, {
  Map<String, dynamic> fallback = const <String, dynamic>{},
}) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return fallback;
}
