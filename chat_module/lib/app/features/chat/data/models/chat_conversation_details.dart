import 'package:get/get.dart';

import '../../../../../api_config.dart';
import '../../../../core/localization/app_translations.dart';
import 'chat_backgrounds_response.dart';

class ChatConversationDetailsModel {
  const ChatConversationDetailsModel({
    required this.conversationId,
    required this.requestedUserId,
    required this.resolvedConversationId,
    required this.openTokenUsed,
    required this.title,
    required this.avatarUrl,
    required this.userId,
    required this.nodeId,
    required this.nodeType,
    required this.link,
    required this.isGroupConversation,
    required this.isOnline,
    required this.lastSeenAt,
    required this.lastSeenAgo,
    required this.typingNameList,
    required this.seenNameList,
    required this.hasMore,
    required this.messagesCount,
    required this.isPinned,
    required this.isMuted,
    required this.isBlocked,
    required this.blockedByMe,
    required this.blockedMe,
    required this.canSendMessages,
    required this.readStatus,
    required this.messages,
  });

  final int conversationId;
  final int requestedUserId;
  final int resolvedConversationId;
  final bool openTokenUsed;
  final String title;
  final String avatarUrl;
  final int userId;
  final int nodeId;
  final String nodeType;
  final String link;
  final bool isGroupConversation;
  final bool isOnline;
  final String lastSeenAt;
  final String lastSeenAgo;
  final String typingNameList;
  final String seenNameList;
  final bool hasMore;
  final int messagesCount;
  final bool isPinned;
  final bool isMuted;
  final bool isBlocked;
  final bool blockedByMe;
  final bool blockedMe;
  final bool canSendMessages;
  final ChatReadStatusModel readStatus;
  final List<ChatMessageModel> messages;

  factory ChatConversationDetailsModel.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final conversation = _asMap(data['conversation'], fallback: data);
    final preferences = _asMap(conversation['preferences']);
    final relationship = _asMap(
      conversation['relationship'],
      fallback: _asMap(data['relationship']),
    );
    final rawMessages = (conversation['messages'] as List?) ?? const [];

    return ChatConversationDetailsModel(
      conversationId: _parseInt(
        conversation['conversation_id'] ?? data['conversation_id'],
      ),
      requestedUserId: _parseInt(data['requested_user_id']),
      resolvedConversationId: _parseInt(data['resolved_conversation_id']),
      openTokenUsed: _parseBool(data['open_token_used']),
      title:
          conversation['name']?.toString() ??
          conversation['name_list']?.toString() ??
          '',
      avatarUrl: conversation['picture']?.toString() ?? '',
      userId: _parseInt(conversation['user_id']),
      nodeId: _parseInt(conversation['node_id']),
      nodeType: conversation['node_type']?.toString() ?? '',
      link: conversation['link']?.toString() ?? '',
      isGroupConversation:
          _parseBool(conversation['multiple_recipients']) ||
          conversation['node_type']?.toString() == 'group',
      isOnline: _parseBool(
        conversation['user_is_online'] ?? conversation['is_online'],
      ),
      lastSeenAt: conversation['user_last_seen']?.toString() ?? '',
      lastSeenAgo: conversation['user_last_seen_ago']?.toString() ?? '',
      typingNameList: conversation['typing_name_list']?.toString() ?? '',
      seenNameList: conversation['seen_name_list']?.toString() ?? '',
      hasMore: _parseBool(conversation['has_more']),
      messagesCount: _parseInt(conversation['messages_count']),
      isPinned: _parseBool(
        conversation['is_pinned'] ?? preferences['is_pinned'],
      ),
      isMuted: _parseBool(conversation['is_muted'] ?? preferences['is_muted']),
      isBlocked: _parseBool(
        conversation['is_blocked'] ?? relationship['is_blocked'],
      ),
      blockedByMe: _parseBool(
        conversation['blocked_by_me'] ?? relationship['blocked_by_me'],
      ),
      blockedMe: _parseBool(
        conversation['blocked_me'] ?? relationship['blocked_me'],
      ),
      canSendMessages: _parseBool(
        conversation['can_send_messages'] ??
            relationship['can_send_messages'] ??
            true,
      ),
      readStatus: ChatReadStatusModel.fromSources(
        conversation['read_status'],
        fallback: conversation,
      ),
      messages: rawMessages
          .whereType<Map>()
          .map(
            (item) =>
                ChatMessageModel.fromJson(Map<String, dynamic>.from(item)),
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

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
}

class ChatReadStatusModel {
  const ChatReadStatusModel({
    required this.conversationId,
    required this.viewerSeen,
    required this.seenNameList,
    required this.lastSeenMessageId,
    required this.lastMessageId,
    required this.lastMessageUserId,
    required this.userIsOnline,
    required this.userLastSeen,
    required this.userLastSeenAgo,
    required this.hasUserPresenceSignal,
    required this.isBlocked,
    required this.blockedByMe,
    required this.blockedMe,
    required this.canSendMessages,
  });

  final int conversationId;
  final bool viewerSeen;
  final String seenNameList;
  final int lastSeenMessageId;
  final int lastMessageId;
  final int lastMessageUserId;
  final bool userIsOnline;
  final String userLastSeen;
  final String userLastSeenAgo;
  final bool hasUserPresenceSignal;
  final bool isBlocked;
  final bool blockedByMe;
  final bool blockedMe;
  final bool canSendMessages;

  bool get hasSeenSignal =>
      viewerSeen || seenNameList.trim().isNotEmpty || lastSeenMessageId > 0;

  factory ChatReadStatusModel.fromJson(Map<String, dynamic> json) {
    final relationship = _asMap(json['relationship']);
    final hasUserIsOnline =
        (json.containsKey('user_is_online') &&
            json['user_is_online'] != null) ||
        (json.containsKey('is_online') && json['is_online'] != null);
    final hasUserLastSeen =
        (json['user_last_seen']?.toString().trim().isNotEmpty ?? false) ||
        (json['user_last_seen_ago']?.toString().trim().isNotEmpty ?? false);
    return ChatReadStatusModel(
      conversationId: ChatConversationDetailsModel._parseInt(
        json['conversation_id'],
      ),
      viewerSeen: ChatConversationDetailsModel._parseBool(json['viewer_seen']),
      seenNameList: json['seen_name_list']?.toString() ?? '',
      lastSeenMessageId: ChatConversationDetailsModel._parseInt(
        json['last_seen_message_id'],
      ),
      lastMessageId: ChatConversationDetailsModel._parseInt(
        json['last_message_id'],
      ),
      lastMessageUserId: ChatConversationDetailsModel._parseInt(
        json['last_message_user_id'],
      ),
      userIsOnline: ChatConversationDetailsModel._parseBool(
        json['user_is_online'] ?? json['is_online'],
      ),
      userLastSeen: json['user_last_seen']?.toString() ?? '',
      userLastSeenAgo: json['user_last_seen_ago']?.toString() ?? '',
      hasUserPresenceSignal: hasUserIsOnline || hasUserLastSeen,
      isBlocked: ChatConversationDetailsModel._parseBool(
        json['is_blocked'] ?? relationship['is_blocked'],
      ),
      blockedByMe: ChatConversationDetailsModel._parseBool(
        json['blocked_by_me'] ?? relationship['blocked_by_me'],
      ),
      blockedMe: ChatConversationDetailsModel._parseBool(
        json['blocked_me'] ?? relationship['blocked_me'],
      ),
      canSendMessages: ChatConversationDetailsModel._parseBool(
        json['can_send_messages'] ?? relationship['can_send_messages'] ?? true,
      ),
    );
  }

  factory ChatReadStatusModel.fromSources(
    dynamic raw, {
    Map<String, dynamic>? fallback,
  }) {
    final normalized = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    if (normalized.isNotEmpty) {
      return ChatReadStatusModel.fromJson(normalized);
    }
    return ChatReadStatusModel.fromJson(fallback ?? const <String, dynamic>{});
  }
}

class ChatMessageChangesResponse {
  const ChatMessageChangesResponse({
    required this.conversationId,
    required this.nextCursor,
    required this.hasMore,
    required this.newMessages,
    required this.updatedMessages,
    required this.deletedMessageIds,
    required this.background,
    required this.readStatus,
  });

  final int conversationId;
  final int nextCursor;
  final bool hasMore;
  final List<ChatMessageModel> newMessages;
  final List<ChatMessageModel> updatedMessages;
  final List<int> deletedMessageIds;
  final ChatBackgroundModel? background;
  final ChatReadStatusModel? readStatus;

  factory ChatMessageChangesResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final newMessagesRaw = (data['new_messages'] as List?) ?? const [];
    final updatedMessagesRaw = (data['updated_messages'] as List?) ?? const [];
    final deletedIdsRaw = (data['deleted_message_ids'] as List?) ?? const [];
    final conversationUpdates = _asMap(data['conversation_updates']);
    final background = _parseConversationBackgroundObject(
      data['background'] ?? conversationUpdates['background'],
    );
    final readStatus = _parseReadStatus(
      conversationUpdates['read_status'] ?? data['read_status'],
    );

    return ChatMessageChangesResponse(
      conversationId: ChatConversationDetailsModel._parseInt(
        data['conversation_id'],
      ),
      nextCursor: ChatConversationDetailsModel._parseInt(data['next_cursor']),
      hasMore: ChatConversationDetailsModel._parseBool(data['has_more']),
      newMessages: newMessagesRaw
          .whereType<Map>()
          .map(
            (item) =>
                ChatMessageModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      updatedMessages: updatedMessagesRaw
          .whereType<Map>()
          .map(
            (item) =>
                ChatMessageModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      deletedMessageIds: deletedIdsRaw
          .map(ChatConversationDetailsModel._parseInt)
          .where((id) => id != 0)
          .toList(),
      background: background,
      readStatus: readStatus,
    );
  }
}

class ChatConversationStatusResponse {
  const ChatConversationStatusResponse({required this.readStatus});

  final ChatReadStatusModel readStatus;

  factory ChatConversationStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    return ChatConversationStatusResponse(
      readStatus: ChatReadStatusModel.fromSources(
        data['read_status'],
        fallback: data,
      ),
    );
  }
}

class ChatConversationPreferences {
  const ChatConversationPreferences({
    required this.conversationId,
    required this.targetUserId,
    required this.isPinned,
    required this.isMuted,
  });

  final int conversationId;
  final int targetUserId;
  final bool isPinned;
  final bool isMuted;

  factory ChatConversationPreferences.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final preferences = _asMap(
      data['preferences'],
      fallback: _asMap(json['preferences'], fallback: data),
    );

    return ChatConversationPreferences(
      conversationId: ChatConversationDetailsModel._parseInt(
        data['conversation_id'] ?? preferences['conversation_id'],
      ),
      targetUserId: ChatConversationDetailsModel._parseInt(
        data['target_user_id'] ?? preferences['target_user_id'],
      ),
      isPinned: ChatConversationDetailsModel._parseBool(
        preferences['is_pinned'],
      ),
      isMuted: ChatConversationDetailsModel._parseBool(preferences['is_muted']),
    );
  }
}

class ChatMessagesResponse {
  const ChatMessagesResponse({
    required this.conversationId,
    required this.messages,
    required this.hasMore,
    required this.nextOffset,
    required this.typingNameList,
    required this.seenNameList,
    required this.userIsOnline,
    required this.userLastSeen,
    required this.userLastSeenAgo,
    required this.readStatus,
  });

  final int conversationId;
  final List<ChatMessageModel> messages;
  final bool hasMore;
  final int? nextOffset;
  final String typingNameList;
  final String seenNameList;
  final bool userIsOnline;
  final String userLastSeen;
  final String userLastSeenAgo;
  final ChatReadStatusModel readStatus;

  factory ChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawMessages = (data['messages'] as List?) ?? const [];

    return ChatMessagesResponse(
      conversationId: ChatConversationDetailsModel._parseInt(
        data['conversation_id'],
      ),
      messages: rawMessages
          .whereType<Map>()
          .map(
            (item) =>
                ChatMessageModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      hasMore: ChatConversationDetailsModel._parseBool(data['has_more']),
      nextOffset: data['next_offset'] == null
          ? null
          : ChatConversationDetailsModel._parseInt(data['next_offset']),
      typingNameList: data['typing_name_list']?.toString() ?? '',
      seenNameList: data['seen_name_list']?.toString() ?? '',
      userIsOnline: ChatConversationDetailsModel._parseBool(
        data['user_is_online'],
      ),
      userLastSeen: data['user_last_seen']?.toString() ?? '',
      userLastSeenAgo: data['user_last_seen_ago']?.toString() ?? '',
      readStatus: ChatReadStatusModel.fromSources(
        data['read_status'],
        fallback: data,
      ),
    );
  }
}

ChatReadStatusModel? _parseReadStatus(dynamic value) {
  if (value is! Map) {
    return null;
  }
  final status = ChatReadStatusModel.fromJson(Map<String, dynamic>.from(value));
  return status.hasSeenSignal ||
          status.conversationId != 0 ||
          status.userIsOnline ||
          status.userLastSeen.isNotEmpty ||
          status.userLastSeenAgo.isNotEmpty
      ? status
      : null;
}

class ChatSendMessageResult {
  const ChatSendMessageResult({
    required this.conversationId,
    required this.lastMessageId,
    required this.lastMessage,
    required this.eventId,
    required this.nextCursor,
  });

  final int conversationId;
  final int lastMessageId;
  final ChatMessageModel? lastMessage;
  final int eventId;
  final int nextCursor;

  factory ChatSendMessageResult.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final lastMessage = data['last_message'];

    return ChatSendMessageResult(
      conversationId: ChatConversationDetailsModel._parseInt(
        data['conversation_id'],
      ),
      lastMessageId: ChatConversationDetailsModel._parseInt(
        data['last_message_id'],
      ),
      lastMessage: lastMessage is Map
          ? ChatMessageModel.fromJson(Map<String, dynamic>.from(lastMessage))
          : null,
      eventId: ChatConversationDetailsModel._parseInt(data['event_id']),
      nextCursor: ChatConversationDetailsModel._parseInt(data['next_cursor']),
    );
  }
}

const _stickerMessagePlaceholder = '\u200B';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.text,
    required this.editableText,
    required this.imageUrl,
    required this.videoUrl,
    required this.voiceNoteUrl,
    required this.replyToMessageId,
    required this.replyToMessage,
    required this.forwardedFromMessageId,
    required this.forwardedFromMessage,
    required this.stickerId,
    required this.stickerUrl,
    required this.stickerPreviewUrl,
    required this.stickerPackName,
    required this.stickerTitle,
    required this.time,
    required this.timeAgo,
    required this.senderName,
    required this.senderPicture,
    required this.productPostId,
    required this.messageType,
    required this.postId,
    required this.reelId,
    required this.sharedItem,
    required this.storyAction,
    required this.location,
    required this.contact,
    required this.fileAttachment,
    required this.storyId,
    required this.storyMediaId,
    required this.storyReaction,
    required this.productName,
    required this.productPrice,
    required this.productDescription,
    required this.productImageUrl,
    required this.productActionUrl,
    required this.reactionsTotalCount,
    required this.iReact,
    required this.topReactionType,
    required this.myReactionType,
    required this.reactionCounts,
  });

  final int id;
  final int conversationId;
  final int userId;
  final String text;
  final String editableText;
  final String imageUrl;
  final String videoUrl;
  final String voiceNoteUrl;
  final int replyToMessageId;
  final ChatReplyMessageModel? replyToMessage;
  final int forwardedFromMessageId;
  final ChatReplyMessageModel? forwardedFromMessage;
  final int stickerId;
  final String stickerUrl;
  final String stickerPreviewUrl;
  final String stickerPackName;
  final String stickerTitle;
  final String time;
  final String timeAgo;
  final String senderName;
  final String senderPicture;
  final int productPostId;
  final String messageType;
  final int postId;
  final int reelId;
  final ChatSharedAttachmentModel? sharedItem;
  final ChatStoryActionModel? storyAction;
  final ChatLocationModel? location;
  final ChatContactAttachmentModel? contact;
  final ChatFileAttachmentModel? fileAttachment;
  final int storyId;
  final int storyMediaId;
  final String storyReaction;
  final String productName;
  final String productPrice;
  final String productDescription;
  final String productImageUrl;
  final String productActionUrl;
  final int reactionsTotalCount;
  final bool iReact;
  final String topReactionType;
  final String myReactionType;
  final Map<String, int> reactionCounts;

  String get timeLabel => timeAgo.isNotEmpty ? timeAgo : time;

  bool get hasText => text.trim().isNotEmpty;

  bool get hasImage => imageUrl.trim().isNotEmpty;

  bool get hasVideo => videoUrl.trim().isNotEmpty;

  bool get hasVoiceNote => !hasSticker && voiceNoteUrl.trim().isNotEmpty;

  bool get hasSticker =>
      stickerId != 0 ||
      stickerUrl.trim().isNotEmpty ||
      stickerPreviewUrl.trim().isNotEmpty;

  String get resolvedStickerUrl =>
      stickerUrl.trim().isNotEmpty ? stickerUrl : stickerPreviewUrl;

  bool get hasProduct =>
      productPostId > 0 ||
      productName.trim().isNotEmpty ||
      productImageUrl.trim().isNotEmpty;

  bool get isSharedMessage =>
      messageType == 'shared_post' || messageType == 'shared_reel';

  bool get hasSharedItem => sharedItem != null || isSharedMessage;

  bool get hasStoryAction =>
      storyAction != null ||
      storyId > 0 ||
      storyMediaId > 0 ||
      messageType == 'story_reply' ||
      messageType == 'story_reaction';

  bool get hasLocation =>
      (location?.isMeaningful ?? false) || messageType == 'location';

  bool get hasContact =>
      (contact?.isMeaningful ?? false) || messageType == 'contact';

  bool get hasFileAttachment =>
      (fileAttachment?.isMeaningful ?? false) || messageType == 'file';

  bool get hasReactions => reactionsTotalCount > 0;

  String get displayedReactionType {
    if (iReact && myReactionType.trim().isNotEmpty) {
      return myReactionType.trim();
    }
    return topReactionType.trim();
  }

  String get topReactionEmoji => switch (topReactionType) {
    'love' => '❤️',
    'haha' => '😂',
    'yay' => '🎉',
    'wow' => '😮',
    'sad' => '😢',
    'angry' => '😡',
    _ => '👍',
  };

  ChatMessageModel copyWith({
    String? text,
    String? editableText,
    String? imageUrl,
    String? videoUrl,
    String? voiceNoteUrl,
    String? time,
    String? timeAgo,
    String? senderName,
    String? senderPicture,
    int? replyToMessageId,
    ChatReplyMessageModel? replyToMessage,
    int? forwardedFromMessageId,
    ChatReplyMessageModel? forwardedFromMessage,
    int? stickerId,
    String? stickerUrl,
    String? stickerPreviewUrl,
    String? stickerPackName,
    String? stickerTitle,
    int? productPostId,
    String? messageType,
    int? postId,
    int? reelId,
    ChatSharedAttachmentModel? sharedItem,
    ChatStoryActionModel? storyAction,
    ChatLocationModel? location,
    ChatContactAttachmentModel? contact,
    ChatFileAttachmentModel? fileAttachment,
    int? storyId,
    int? storyMediaId,
    String? storyReaction,
    String? productName,
    String? productPrice,
    String? productDescription,
    String? productImageUrl,
    String? productActionUrl,
    int? reactionsTotalCount,
    bool? iReact,
    String? topReactionType,
    String? myReactionType,
    Map<String, int>? reactionCounts,
  }) {
    return ChatMessageModel(
      id: id,
      conversationId: conversationId,
      userId: userId,
      text: text ?? this.text,
      editableText: editableText ?? this.editableText,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      forwardedFromMessageId:
          forwardedFromMessageId ?? this.forwardedFromMessageId,
      forwardedFromMessage: forwardedFromMessage ?? this.forwardedFromMessage,
      stickerId: stickerId ?? this.stickerId,
      stickerUrl: stickerUrl ?? this.stickerUrl,
      stickerPreviewUrl: stickerPreviewUrl ?? this.stickerPreviewUrl,
      stickerPackName: stickerPackName ?? this.stickerPackName,
      stickerTitle: stickerTitle ?? this.stickerTitle,
      time: time ?? this.time,
      timeAgo: timeAgo ?? this.timeAgo,
      senderName: senderName ?? this.senderName,
      senderPicture: senderPicture ?? this.senderPicture,
      productPostId: productPostId ?? this.productPostId,
      messageType: messageType ?? this.messageType,
      postId: postId ?? this.postId,
      reelId: reelId ?? this.reelId,
      sharedItem: sharedItem ?? this.sharedItem,
      storyAction: storyAction ?? this.storyAction,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      fileAttachment: fileAttachment ?? this.fileAttachment,
      storyId: storyId ?? this.storyId,
      storyMediaId: storyMediaId ?? this.storyMediaId,
      storyReaction: storyReaction ?? this.storyReaction,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productDescription: productDescription ?? this.productDescription,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      productActionUrl: productActionUrl ?? this.productActionUrl,
      reactionsTotalCount: reactionsTotalCount ?? this.reactionsTotalCount,
      iReact: iReact ?? this.iReact,
      topReactionType: topReactionType ?? this.topReactionType,
      myReactionType: myReactionType ?? this.myReactionType,
      reactionCounts: reactionCounts ?? this.reactionCounts,
    );
  }

  String get previewText {
    if (hasText) {
      return text;
    }
    if (hasProduct) {
      return productName.isNotEmpty
          ? productName
          : AppTranslations.commonProduct.tr;
    }
    if (hasStoryAction) {
      if (messageType == 'story_reaction') {
        return AppTranslations.chatReactedToStory.tr;
      }
      return AppTranslations.chatRepliedToStory.tr;
    }
    if (hasSharedItem) {
      return sharedItem?.displayTitle ??
          (messageType == 'shared_reel'
              ? AppTranslations.sharedReel.tr
              : AppTranslations.sharedPost.tr);
    }
    if (hasLocation) {
      return location?.displayLabel ?? AppTranslations.commonLocation.tr;
    }
    if (hasContact) {
      return contact?.displayLabel ?? AppTranslations.commonContact.tr;
    }
    if (hasFileAttachment) {
      return fileAttachment?.displayName ?? AppTranslations.chatInfoFiles.tr;
    }
    if (hasVoiceNote) {
      return AppTranslations.homeStatusVoice.tr;
    }
    if (hasSticker) {
      return stickerTitle.isNotEmpty
          ? stickerTitle
          : AppTranslations.commonSticker.tr;
    }
    if (hasImage) {
      return AppTranslations.commonImage.tr;
    }
    if (hasVideo) {
      return AppTranslations.commonVideo.tr;
    }
    return '';
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final post = _asMap(json['post']);
    final product = _asMap(post['product']);
    final photos = (post['photos'] as List?) ?? const [];
    final rawSticker = json['sticker'];
    final sticker = rawSticker is Map
        ? Map<String, dynamic>.from(rawSticker)
        : const <String, dynamic>{};
    final firstPhoto = photos.isNotEmpty && photos.first is Map
        ? Map<String, dynamic>.from(photos.first as Map)
        : const <String, dynamic>{};
    final reactions = _asMap(json['reactions']);
    final rawSharedItem = json['shared_item'];
    final sharedItem = rawSharedItem is Map
        ? ChatSharedAttachmentModel.fromJson(
            Map<String, dynamic>.from(rawSharedItem),
          )
        : null;
    final rawStoryAction = json['story_action'];
    final storyAction = rawStoryAction is Map
        ? ChatStoryActionModel.fromJson(
            Map<String, dynamic>.from(rawStoryAction),
          )
        : null;
    final rawLocation = json['location'];
    final location = rawLocation is Map
        ? ChatLocationModel.fromJson(Map<String, dynamic>.from(rawLocation))
        : ChatLocationModel.fromMessageJson(json);
    final rawContact = json['contact'];
    final contact = rawContact is Map
        ? ChatContactAttachmentModel.fromJson(
            Map<String, dynamic>.from(rawContact),
          )
        : ChatContactAttachmentModel.fromMessageJson(json);
    final rawFile = json['file'];
    final fileAttachment = rawFile is Map
        ? ChatFileAttachmentModel.fromJson(Map<String, dynamic>.from(rawFile))
        : ((json['message_type']?.toString().trim().toLowerCase() ?? '') ==
                  'file' ||
              json['original_name'] != null ||
              json['file_name'] != null)
        ? ChatFileAttachmentModel.fromMessageJson(json)
        : null;
    final rawReplyMessage = json['reply_to_message'];
    final replyToMessage = rawReplyMessage is Map
        ? ChatReplyMessageModel.fromJson(
            Map<String, dynamic>.from(rawReplyMessage),
          )
        : null;
    final rawForwardedMessage = json['forwarded_from_message'];
    final forwardedFromMessage = rawForwardedMessage is Map
        ? ChatReplyMessageModel.fromJson(
            Map<String, dynamic>.from(rawForwardedMessage),
          )
        : null;
    final normalizedReactionCounts = _normalizeReactionCounts(reactions);
    final resolvedTopReactionType = _resolveTopReactionType(
      normalizedReactionCounts,
    );
    final didReact = ChatConversationDetailsModel._parseBool(json['i_react']);
    final myReactionType =
        json['i_reaction']?.toString().trim() ??
        (didReact ? resolvedTopReactionType : '');
    final rawDisplayText =
        json['message_decoded']?.toString() ??
        json['message_orginal_decoded']?.toString() ??
        json['message']?.toString() ??
        '';
    final rawEditableText =
        json['message_orginal_decoded']?.toString() ??
        json['message_orginal']?.toString() ??
        json['message_decoded']?.toString() ??
        json['message']?.toString() ??
        '';

    return ChatMessageModel(
      id: ChatConversationDetailsModel._parseInt(json['message_id']),
      conversationId: ChatConversationDetailsModel._parseInt(
        json['conversation_id'],
      ),
      userId: ChatConversationDetailsModel._parseInt(json['user_id']),
      text: _normalizeMessageText(rawDisplayText),
      editableText: _normalizeEditableMessageText(rawEditableText),
      imageUrl: _normalizeNullableValue(json['image']),
      videoUrl: _normalizeNullableValue(json['video']),
      voiceNoteUrl: _normalizeVoiceNoteUrl(json),
      replyToMessageId: ChatConversationDetailsModel._parseInt(
        json['reply_to_message_id'],
      ),
      replyToMessage: replyToMessage,
      forwardedFromMessageId: ChatConversationDetailsModel._parseInt(
        json['forwarded_from_message_id'],
      ),
      forwardedFromMessage: forwardedFromMessage,
      stickerId: ChatConversationDetailsModel._parseInt(
        json['sticker_id'] ?? sticker['id'],
      ),
      stickerUrl: _normalizeNullableValue(
        json['sticker_image'] ??
            json['sticker_url'] ??
            (rawSticker is String ? rawSticker : null) ??
            sticker['image'],
      ),
      stickerPreviewUrl: _normalizeNullableValue(
        json['sticker_preview'] ?? sticker['preview'],
      ),
      stickerPackName:
          sticker['pack_name']?.toString() ??
          json['sticker_pack']?.toString() ??
          json['sticker_pack_slug']?.toString() ??
          json['sticker_pack_name']?.toString() ??
          '',
      stickerTitle:
          sticker['title']?.toString() ??
          json['sticker_title']?.toString() ??
          '',
      time: json['time']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      senderName:
          json['user_fullname']?.toString() ??
          [
            json['user_firstname']?.toString() ?? '',
            json['user_lastname']?.toString() ?? '',
          ].where((part) => part.trim().isNotEmpty).join(' ').trim(),
      senderPicture: json['user_picture']?.toString() ?? '',
      productPostId: ChatConversationDetailsModel._parseInt(
        json['product_post_id'],
      ),
      messageType: json['message_type']?.toString().trim().toLowerCase() ?? '',
      postId: ChatConversationDetailsModel._parseInt(json['post_id']),
      reelId: ChatConversationDetailsModel._parseInt(json['reel_id']),
      sharedItem: sharedItem,
      storyAction: storyAction,
      location: location,
      contact: contact,
      fileAttachment: fileAttachment,
      storyId: ChatConversationDetailsModel._parseInt(json['story_id']),
      storyMediaId: ChatConversationDetailsModel._parseInt(
        json['story_media_id'],
      ),
      storyReaction:
          json['story_reaction']?.toString().trim().toLowerCase() ?? '',
      productName:
          product['name']?.toString() ?? post['og_title']?.toString() ?? '',
      productPrice:
          product['price_formatted']?.toString() ??
          product['price']?.toString() ??
          '',
      productDescription:
          post['text_plain']?.toString() ??
          post['og_description']?.toString() ??
          '',
      productImageUrl: _normalizeNullableValue(
        firstPhoto['source'] ?? post['og_image'],
      ),
      productActionUrl:
          product['product_download_url']?.toString() ??
          post['post_author_url']?.toString() ??
          '',
      reactionsTotalCount: ChatConversationDetailsModel._parseInt(
        json['reactions_total_count'],
      ),
      iReact: didReact,
      topReactionType: resolvedTopReactionType,
      myReactionType: myReactionType,
      reactionCounts: normalizedReactionCounts,
    );
  }

  static String _normalizeMessageText(String value) {
    return value.replaceAll(_stickerMessagePlaceholder, '').trim();
  }

  static String _normalizeEditableMessageText(String value) {
    final normalized = _normalizeMessageText(value);
    if (normalized.isEmpty) {
      return '';
    }

    final anchorReplaced = normalized.replaceAllMapped(
      RegExp(
        r'<a\s+[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
        caseSensitive: false,
        dotAll: true,
      ),
      (match) {
        final href = (match.group(1) ?? '').trim();
        final label = _stripHtmlTags(match.group(2) ?? '').trim();
        if (href.isEmpty) {
          return label;
        }
        if (label.isEmpty || label == href) {
          return href;
        }
        return href;
      },
    );

    return _stripHtmlTags(anchorReplaced)
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _stripHtmlTags(String value) {
    return value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }

  static Map<String, int> _normalizeReactionCounts(
    Map<String, dynamic> reactions,
  ) {
    final normalized = <String, int>{};
    for (final entry in reactions.entries) {
      final count = ChatConversationDetailsModel._parseInt(entry.value);
      if (count > 0) {
        normalized[entry.key] = count;
      }
    }
    return normalized;
  }

  static String _resolveTopReactionType(Map<String, int> reactions) {
    var topType = '';
    var topCount = -1;
    for (final entry in reactions.entries) {
      final count = entry.value;
      if (count > topCount) {
        topCount = count;
        topType = entry.key;
      }
    }
    return topCount > 0 ? topType : '';
  }

  static String _normalizeNullableValue(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is Map) {
      for (final key in <String>[
        'url',
        'media_url',
        'download_url',
        'source',
      ]) {
        final normalized = _normalizeNullableValue(value[key]);
        if (normalized.isNotEmpty) {
          return normalized;
        }
      }
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
      return _resolveUploadUrl(raw);
    }
    return raw;
  }

  static String _normalizeVoiceNoteUrl(Map<String, dynamic> json) {
    final messageType =
        json['message_type']?.toString().trim().toLowerCase() ?? '';
    final hasStickerPayload =
        messageType == 'sticker' ||
        messageType == 'chat_sticker' ||
        ChatConversationDetailsModel._parseInt(json['sticker_id']) != 0 ||
        _normalizeNullableValue(json['sticker']).isNotEmpty ||
        _normalizeNullableValue(json['sticker_url']).isNotEmpty ||
        _normalizeNullableValue(json['sticker_image']).isNotEmpty;
    if (hasStickerPayload) {
      return '';
    }

    final voiceNote = _normalizeNullableValue(json['voice_note']);
    if (voiceNote.isNotEmpty) {
      return voiceNote;
    }

    final mimeType = json['mime_type']?.toString().trim().toLowerCase() ?? '';
    final isAudioPayload =
        messageType == 'audio' ||
        messageType == 'voice' ||
        messageType == 'voice_note' ||
        mimeType.startsWith('audio/');
    if (!isAudioPayload) {
      return '';
    }

    return _normalizeNullableValue(json['media_url']);
  }
}

String _resolveUploadUrl(String raw) {
  final trimmedBaseUrl = ApiConfig.baseUrl.trim().replaceFirst(
    RegExp(r'/+$'),
    '',
  );
  return '$trimmedBaseUrl/content/uploads/${raw.replaceFirst(RegExp(r'^/+'), '')}';
}

class ChatReplyMessageModel {
  const ChatReplyMessageModel({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.text,
    required this.imageUrl,
    required this.videoUrl,
    required this.voiceNoteUrl,
    required this.stickerId,
    required this.stickerUrl,
    required this.stickerPreviewUrl,
    required this.stickerTitle,
    required this.messageType,
    required this.postId,
    required this.reelId,
    required this.sharedItem,
    required this.storyAction,
    required this.location,
    required this.contact,
    required this.storyId,
    required this.storyMediaId,
    required this.storyReaction,
    required this.productPostId,
    required this.productName,
    required this.time,
    required this.senderName,
  });

  final int id;
  final int conversationId;
  final int userId;
  final String text;
  final String imageUrl;
  final String videoUrl;
  final String voiceNoteUrl;
  final int stickerId;
  final String stickerUrl;
  final String stickerPreviewUrl;
  final String stickerTitle;
  final String messageType;
  final int postId;
  final int reelId;
  final ChatSharedAttachmentModel? sharedItem;
  final ChatStoryActionModel? storyAction;
  final ChatLocationModel? location;
  final ChatContactAttachmentModel? contact;
  final int storyId;
  final int storyMediaId;
  final String storyReaction;
  final int productPostId;
  final String productName;
  final String time;
  final String senderName;

  bool get hasText => text.trim().isNotEmpty;
  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get hasVideo => videoUrl.trim().isNotEmpty;
  bool get hasVoiceNote => !hasSticker && voiceNoteUrl.trim().isNotEmpty;
  bool get hasSticker =>
      stickerId != 0 ||
      stickerUrl.trim().isNotEmpty ||
      stickerPreviewUrl.trim().isNotEmpty;
  bool get isSharedMessage =>
      messageType == 'shared_post' || messageType == 'shared_reel';
  bool get hasSharedItem => sharedItem != null || isSharedMessage;
  bool get hasStoryAction =>
      storyAction != null ||
      storyId > 0 ||
      storyMediaId > 0 ||
      messageType == 'story_reply' ||
      messageType == 'story_reaction';
  bool get hasLocation =>
      (location?.isMeaningful ?? false) || messageType == 'location';
  bool get hasContact =>
      (contact?.isMeaningful ?? false) || messageType == 'contact';
  bool get hasProduct => productPostId > 0 || productName.trim().isNotEmpty;

  String get previewText {
    if (hasText) {
      return text;
    }
    if (hasProduct) {
      return productName.isNotEmpty
          ? productName
          : AppTranslations.commonProduct.tr;
    }
    if (hasStoryAction) {
      if (messageType == 'story_reaction') {
        return AppTranslations.chatReactedToStory.tr;
      }
      return AppTranslations.chatRepliedToStory.tr;
    }
    if (hasSharedItem) {
      return sharedItem?.displayTitle ??
          (messageType == 'shared_reel'
              ? AppTranslations.sharedReel.tr
              : AppTranslations.sharedPost.tr);
    }
    if (hasLocation) {
      return location?.displayLabel ?? AppTranslations.commonLocation.tr;
    }
    if (hasContact) {
      return contact?.displayLabel ?? AppTranslations.commonContact.tr;
    }
    if (hasVoiceNote) {
      return AppTranslations.homeStatusVoice.tr;
    }
    if (hasSticker) {
      return stickerTitle.isNotEmpty
          ? stickerTitle
          : AppTranslations.commonSticker.tr;
    }
    if (hasImage) {
      return AppTranslations.commonImage.tr;
    }
    if (hasVideo) {
      return AppTranslations.commonVideo.tr;
    }
    return AppTranslations.chatReplyOriginalUnavailable.tr;
  }

  factory ChatReplyMessageModel.fromJson(Map<String, dynamic> json) {
    final post = _asMap(json['post']);
    final product = _asMap(post['product']);
    final rawSticker = json['sticker'];
    final sticker = rawSticker is Map
        ? Map<String, dynamic>.from(rawSticker)
        : const <String, dynamic>{};
    final rawSharedItem = json['shared_item'];
    final sharedItem = rawSharedItem is Map
        ? ChatSharedAttachmentModel.fromJson(
            Map<String, dynamic>.from(rawSharedItem),
          )
        : null;
    final rawStoryAction = json['story_action'];
    final storyAction = rawStoryAction is Map
        ? ChatStoryActionModel.fromJson(
            Map<String, dynamic>.from(rawStoryAction),
          )
        : null;
    final rawLocation = json['location'];
    final location = rawLocation is Map
        ? ChatLocationModel.fromJson(Map<String, dynamic>.from(rawLocation))
        : ChatLocationModel.fromMessageJson(json);
    final rawContact = json['contact'];
    final contact = rawContact is Map
        ? ChatContactAttachmentModel.fromJson(
            Map<String, dynamic>.from(rawContact),
          )
        : ChatContactAttachmentModel.fromMessageJson(json);
    final rawText =
        json['message_decoded']?.toString() ??
        json['message_orginal_decoded']?.toString() ??
        json['message']?.toString() ??
        '';

    return ChatReplyMessageModel(
      id: ChatConversationDetailsModel._parseInt(
        json['message_id'] ?? json['id'],
      ),
      conversationId: ChatConversationDetailsModel._parseInt(
        json['conversation_id'],
      ),
      userId: ChatConversationDetailsModel._parseInt(json['user_id']),
      text: ChatMessageModel._normalizeMessageText(rawText),
      imageUrl: ChatMessageModel._normalizeNullableValue(json['image']),
      videoUrl: ChatMessageModel._normalizeNullableValue(json['video']),
      voiceNoteUrl: ChatMessageModel._normalizeVoiceNoteUrl(json),
      stickerId: ChatConversationDetailsModel._parseInt(
        json['sticker_id'] ?? sticker['id'],
      ),
      stickerUrl: ChatMessageModel._normalizeNullableValue(
        json['sticker_image'] ??
            json['sticker_url'] ??
            (rawSticker is String ? rawSticker : null) ??
            sticker['image'],
      ),
      stickerPreviewUrl: ChatMessageModel._normalizeNullableValue(
        json['sticker_preview'] ?? sticker['preview'],
      ),
      stickerTitle:
          sticker['title']?.toString() ??
          json['sticker_title']?.toString() ??
          '',
      messageType: json['message_type']?.toString().trim().toLowerCase() ?? '',
      postId: ChatConversationDetailsModel._parseInt(json['post_id']),
      reelId: ChatConversationDetailsModel._parseInt(json['reel_id']),
      sharedItem: sharedItem,
      storyAction: storyAction,
      location: location,
      contact: contact,
      storyId: ChatConversationDetailsModel._parseInt(json['story_id']),
      storyMediaId: ChatConversationDetailsModel._parseInt(
        json['story_media_id'],
      ),
      storyReaction:
          json['story_reaction']?.toString().trim().toLowerCase() ?? '',
      productPostId: ChatConversationDetailsModel._parseInt(
        json['product_post_id'],
      ),
      productName:
          product['name']?.toString() ?? post['og_title']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      senderName:
          json['user_fullname']?.toString() ??
          [
            json['user_firstname']?.toString() ?? '',
            json['user_lastname']?.toString() ?? '',
          ].where((part) => part.trim().isNotEmpty).join(' ').trim(),
    );
  }
}

class ChatLocationModel {
  const ChatLocationModel({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String name;
  final String address;

  bool get hasDetails => name.trim().isNotEmpty || address.trim().isNotEmpty;
  bool get hasCoordinates => latitude != 0 || longitude != 0;
  bool get isMeaningful => hasDetails || hasCoordinates;

  String get displayLabel {
    if (name.trim().isNotEmpty) {
      return name.trim();
    }
    if (address.trim().isNotEmpty) {
      return address.trim();
    }
    if (hasCoordinates) {
      return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    }
    return AppTranslations.commonLocation.tr;
  }

  String get subtitle {
    if (address.trim().isNotEmpty &&
        address.trim().toLowerCase() != name.trim().toLowerCase()) {
      return address.trim();
    }
    if (hasCoordinates) {
      return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    }
    return '';
  }

  Uri? get externalMapUri {
    if (!hasCoordinates) {
      return null;
    }
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
  }

  factory ChatLocationModel.fromJson(Map<String, dynamic> json) {
    return ChatLocationModel(
      latitude: _parseDouble(
        json['latitude'] ?? json['lat'] ?? json['location_latitude'],
      ),
      longitude: _parseDouble(
        json['longitude'] ?? json['lng'] ?? json['location_longitude'],
      ),
      name:
          json['name']?.toString() ??
          json['location_name']?.toString() ??
          json['title']?.toString() ??
          '',
      address:
          json['address']?.toString() ??
          json['location_address']?.toString() ??
          '',
    );
  }

  factory ChatLocationModel.fromMessageJson(Map<String, dynamic> json) {
    final latitude = _parseDouble(
      json['latitude'] ?? json['lat'] ?? json['location_latitude'],
    );
    final longitude = _parseDouble(
      json['longitude'] ?? json['lng'] ?? json['location_longitude'],
    );
    final name =
        json['location_name']?.toString() ?? json['name']?.toString() ?? '';
    final address =
        json['location_address']?.toString() ??
        json['address']?.toString() ??
        '';
    return ChatLocationModel(
      latitude: latitude,
      longitude: longitude,
      name: name,
      address: address,
    );
  }
}

class ChatContactAttachmentModel {
  const ChatContactAttachmentModel({
    required this.displayName,
    required this.phoneNumber,
    required this.phoneLabel,
  });

  final String displayName;
  final String phoneNumber;
  final String phoneLabel;

  bool get isMeaningful =>
      displayName.trim().isNotEmpty || phoneNumber.trim().isNotEmpty;

  String get displayLabel {
    if (displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    if (phoneNumber.trim().isNotEmpty) {
      return phoneNumber.trim();
    }
    return AppTranslations.commonContact.tr;
  }

  String get subtitle {
    final number = phoneNumber.trim();
    if (number.isEmpty) {
      return '';
    }
    final label = phoneLabel.trim();
    return label.isEmpty ? number : '$label • $number';
  }

  Uri? get phoneUri {
    final number = phoneNumber.trim();
    if (number.isEmpty) {
      return null;
    }
    return Uri.parse('tel:$number');
  }

  factory ChatContactAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ChatContactAttachmentModel(
      displayName:
          json['display_name']?.toString() ??
          json['contact_name']?.toString() ??
          json['name']?.toString() ??
          '',
      phoneNumber:
          json['phone_number']?.toString() ?? json['phone']?.toString() ?? '',
      phoneLabel:
          json['phone_label']?.toString() ?? json['label']?.toString() ?? '',
    );
  }

  factory ChatContactAttachmentModel.fromMessageJson(
    Map<String, dynamic> json,
  ) {
    return ChatContactAttachmentModel(
      displayName:
          json['contact_name']?.toString() ??
          json['display_name']?.toString() ??
          json['name']?.toString() ??
          '',
      phoneNumber:
          json['phone_number']?.toString() ?? json['phone']?.toString() ?? '',
      phoneLabel:
          json['phone_label']?.toString() ?? json['label']?.toString() ?? '',
    );
  }
}

class ChatFileAttachmentModel {
  const ChatFileAttachmentModel({
    required this.source,
    required this.url,
    required this.downloadUrl,
    required this.originalName,
    required this.mimeType,
    required this.extension,
    required this.fileSize,
  });

  final String source;
  final String url;
  final String downloadUrl;
  final String originalName;
  final String mimeType;
  final String extension;
  final int fileSize;

  String get bestUrl {
    for (final value in <String>[downloadUrl, url, source]) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String get displayName {
    if (originalName.trim().isNotEmpty) {
      return originalName.trim();
    }
    final target = bestUrl;
    if (target.isEmpty) {
      return AppTranslations.chatInfoFiles.tr;
    }
    final uri = Uri.tryParse(target);
    final path = uri?.path ?? target;
    final segments = path.split('/');
    return segments.isEmpty ? AppTranslations.chatInfoFiles.tr : segments.last;
  }

  String get normalizedExtension {
    final ext = extension.trim().toLowerCase();
    if (ext.isNotEmpty) {
      return ext;
    }
    final name = displayName.toLowerCase();
    final index = name.lastIndexOf('.');
    if (index == -1 || index == name.length - 1) {
      return '';
    }
    return name.substring(index + 1);
  }

  bool get isMeaningful =>
      bestUrl.isNotEmpty ||
      originalName.trim().isNotEmpty ||
      mimeType.trim().isNotEmpty;

  factory ChatFileAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ChatFileAttachmentModel(
      source: ChatMessageModel._normalizeNullableValue(json['source']),
      url: ChatMessageModel._normalizeNullableValue(json['url']),
      downloadUrl: ChatMessageModel._normalizeNullableValue(
        json['download_url'],
      ),
      originalName:
          json['original_name']?.toString() ??
          json['file_name']?.toString() ??
          '',
      mimeType: json['mime_type']?.toString().trim().toLowerCase() ?? '',
      extension: json['extension']?.toString().trim().toLowerCase() ?? '',
      fileSize: ChatConversationDetailsModel._parseInt(json['file_size']),
    );
  }

  factory ChatFileAttachmentModel.fromMessageJson(Map<String, dynamic> json) {
    return ChatFileAttachmentModel(
      source: ChatMessageModel._normalizeNullableValue(
        json['source'] ?? json['file'],
      ),
      url: ChatMessageModel._normalizeNullableValue(
        json['url'] ?? json['media_url'],
      ),
      downloadUrl: ChatMessageModel._normalizeNullableValue(
        json['download_url'] ?? json['media_url'] ?? json['url'],
      ),
      originalName:
          json['original_name']?.toString() ??
          json['file_name']?.toString() ??
          json['name']?.toString() ??
          '',
      mimeType: json['mime_type']?.toString().trim().toLowerCase() ?? '',
      extension: json['extension']?.toString().trim().toLowerCase() ?? '',
      fileSize: ChatConversationDetailsModel._parseInt(json['file_size']),
    );
  }

  Map<String, dynamic> toRequestPayload() {
    return <String, dynamic>{
      if (source.trim().isNotEmpty) 'source': source.trim(),
      if (originalName.trim().isNotEmpty) 'original_name': originalName.trim(),
      if (mimeType.trim().isNotEmpty) 'mime_type': mimeType.trim(),
      if (extension.trim().isNotEmpty) 'extension': extension.trim(),
      if (fileSize > 0) 'file_size': fileSize,
    };
  }
}

class ChatSharedAttachmentModel {
  const ChatSharedAttachmentModel({
    required this.id,
    required this.type,
    required this.postId,
    required this.reelId,
    required this.postType,
    required this.title,
    required this.text,
    required this.caption,
    required this.source,
    required this.file,
    required this.thumbnail,
    required this.mediaUrl,
    required this.url,
    required this.mimeType,
    required this.authorName,
  });

  final int id;
  final String type;
  final int postId;
  final int reelId;
  final String postType;
  final String title;
  final String text;
  final String caption;
  final String source;
  final String file;
  final String thumbnail;
  final String mediaUrl;
  final String url;
  final String mimeType;
  final String authorName;

  bool get isPost => type == 'post';
  bool get isReel => type == 'reel';
  bool get isImage =>
      type == 'image' ||
      mimeType.trim().toLowerCase().startsWith('image/') ||
      _looksLikeImageUrl(bestUrl);
  bool get isVideo =>
      type == 'video' ||
      mimeType.trim().toLowerCase().startsWith('video/') ||
      _looksLikeVideoUrl(bestUrl);
  bool get isAudio =>
      type == 'audio' ||
      mimeType.trim().toLowerCase().startsWith('audio/') ||
      _looksLikeAudioUrl(bestUrl);
  String get bestUrl {
    for (final value in <String>[url, mediaUrl, file, source, thumbnail]) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String get previewImageUrl {
    for (final value in <String>[thumbnail, mediaUrl, file, source, url]) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && _looksLikeImageUrl(trimmed)) {
        return trimmed;
      }
    }
    return '';
  }

  bool get hasThumbnail => previewImageUrl.isNotEmpty;
  String get displayTitle {
    for (final value in <String>[title, caption, text]) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return isReel
        ? AppTranslations.sharedReel.tr
        : AppTranslations.sharedPost.tr;
  }

  factory ChatSharedAttachmentModel.fromJson(Map<String, dynamic> json) {
    final author = _asMap(json['author']);
    return ChatSharedAttachmentModel(
      id: ChatConversationDetailsModel._parseInt(json['id']),
      type: json['type']?.toString().trim().toLowerCase() ?? '',
      postId: ChatConversationDetailsModel._parseInt(json['post_id']),
      reelId: ChatConversationDetailsModel._parseInt(json['reel_id']),
      postType: json['post_type']?.toString().trim().toLowerCase() ?? '',
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      source: ChatMessageModel._normalizeNullableValue(json['source']),
      file: ChatMessageModel._normalizeNullableValue(json['file']),
      thumbnail: ChatMessageModel._normalizeNullableValue(json['thumbnail']),
      mediaUrl: ChatMessageModel._normalizeNullableValue(json['media_url']),
      url: ChatMessageModel._normalizeNullableValue(json['url']),
      mimeType: json['mime_type']?.toString().trim().toLowerCase() ?? '',
      authorName:
          author['user_fullname']?.toString() ??
          author['user_name']?.toString() ??
          '',
    );
  }
}

class ChatStoryActionModel {
  const ChatStoryActionModel({
    required this.actionType,
    required this.reaction,
    required this.story,
  });

  final String actionType;
  final String reaction;
  final ChatStoryAttachmentModel? story;

  factory ChatStoryActionModel.fromJson(Map<String, dynamic> json) {
    final rawStory = json['story'];
    return ChatStoryActionModel(
      actionType: json['action_type']?.toString().trim().toLowerCase() ?? '',
      reaction: json['reaction']?.toString().trim().toLowerCase() ?? '',
      story: rawStory is Map
          ? ChatStoryAttachmentModel.fromJson(
              Map<String, dynamic>.from(rawStory),
            )
          : null,
    );
  }
}

class ChatStoryAttachmentModel {
  const ChatStoryAttachmentModel({
    required this.storyId,
    required this.storyMediaId,
    required this.ownerUserId,
    required this.authorName,
    required this.authorPhoto,
    required this.mediaType,
    required this.mediaSrc,
    required this.mediaPreview,
    required this.mimeType,
    required this.text,
    required this.time,
  });

  final int storyId;
  final int storyMediaId;
  final int ownerUserId;
  final String authorName;
  final String authorPhoto;
  final String mediaType;
  final String mediaSrc;
  final String mediaPreview;
  final String mimeType;
  final String text;
  final String time;

  String get displayImageUrl {
    if (mediaPreview.trim().isNotEmpty) {
      return mediaPreview;
    }
    return mediaSrc;
  }

  factory ChatStoryAttachmentModel.fromJson(Map<String, dynamic> json) {
    final author = _asMap(json['author']);
    final media = _asMap(json['media']);
    return ChatStoryAttachmentModel(
      storyId: ChatConversationDetailsModel._parseInt(json['story_id']),
      storyMediaId: ChatConversationDetailsModel._parseInt(
        json['story_media_id'],
      ),
      ownerUserId: ChatConversationDetailsModel._parseInt(
        json['owner_user_id'],
      ),
      authorName:
          author['user_fullname']?.toString() ??
          author['name']?.toString() ??
          author['user_name']?.toString() ??
          '',
      authorPhoto: ChatMessageModel._normalizeNullableValue(author['photo']),
      mediaType: media['type']?.toString().trim().toLowerCase() ?? '',
      mediaSrc: ChatMessageModel._normalizeNullableValue(media['src']),
      mediaPreview: ChatMessageModel._normalizeNullableValue(media['preview']),
      mimeType: media['mime_type']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
    );
  }
}

ChatBackgroundModel? _parseConversationBackgroundObject(dynamic raw) {
  if (raw is! Map) {
    return null;
  }
  final mapped = Map<String, dynamic>.from(raw);
  final type = mapped['type']?.toString().trim() ?? '';
  final value = mapped['value']?.toString().trim() ?? '';
  final preview = mapped['preview']?.toString().trim() ?? '';
  if (type.isEmpty && value.isEmpty && preview.isEmpty) {
    return null;
  }
  return ChatBackgroundModel.fromJson(mapped);
}

bool _looksLikeImageUrl(String value) {
  return _matchesUrlExtension(value, const <String>[
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
  ]);
}

bool _looksLikeVideoUrl(String value) {
  return _matchesUrlExtension(value, const <String>[
    'mp4',
    'mov',
    'm4v',
    'webm',
    'mkv',
    'avi',
    '3gp',
  ]);
}

bool _looksLikeAudioUrl(String value) {
  return _matchesUrlExtension(value, const <String>[
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'oga',
  ]);
}

bool _matchesUrlExtension(String value, List<String> extensions) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final uri = Uri.tryParse(trimmed);
  final path = (uri?.path ?? trimmed).toLowerCase();
  for (final extension in extensions) {
    if (path.endsWith('.$extension')) {
      return true;
    }
  }
  return false;
}

double _parseDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
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
