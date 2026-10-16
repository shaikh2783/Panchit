import '../models/chat_conversation_details.dart';
import '../models/chat_conversations_response.dart';

class ChatCacheSerializers {
  ChatCacheSerializers._();

  static ChatConversationsResponse decodeConversationsResponse(
    Map<String, dynamic> json,
  ) {
    return ChatConversationsResponse.fromJson(json);
  }

  static Map<String, dynamic> encodeConversationsResponse(
    ChatConversationsResponse response,
  ) {
    return <String, dynamic>{
      'message': response.message,
      'data': <String, dynamic>{
        'implemented': response.implemented,
        'scaffold_only': response.scaffoldOnly,
        'endpoint': response.endpoint,
        'count': response.count,
        'offset': response.offset,
        'next_offset': response.nextOffset,
        'has_more': response.hasMore,
        'items': response.conversations
            .map(_encodeConversationModel)
            .toList(growable: false),
      },
    };
  }

  static ChatConversationDetailsModel decodeConversationDetails(
    Map<String, dynamic> json,
  ) {
    return ChatConversationDetailsModel.fromJson(json);
  }

  static Map<String, dynamic> encodeConversationDetails(
    ChatConversationDetailsModel details,
  ) {
    return <String, dynamic>{
      'data': <String, dynamic>{
        'requested_user_id': details.requestedUserId,
        'resolved_conversation_id': details.resolvedConversationId,
        'open_token_used': details.openTokenUsed,
        'conversation': <String, dynamic>{
          'conversation_id': details.conversationId,
          'name': details.title,
          'picture': details.avatarUrl,
          'user_id': details.userId,
          'node_id': details.nodeId,
          'node_type': details.nodeType,
          'link': details.link,
          'multiple_recipients': details.isGroupConversation,
          'user_is_online': details.isOnline,
          'user_last_seen': details.lastSeenAt,
          'user_last_seen_ago': details.lastSeenAgo,
          'typing_name_list': details.typingNameList,
          'seen_name_list': details.seenNameList,
          'has_more': details.hasMore,
          'messages_count': details.messagesCount,
          'is_pinned': details.isPinned,
          'is_muted': details.isMuted,
          'is_blocked': details.isBlocked,
          'blocked_by_me': details.blockedByMe,
          'blocked_me': details.blockedMe,
          'can_send_messages': details.canSendMessages,
          'read_status': _encodeReadStatus(details.readStatus),
          'messages': details.messages
              .map(_encodeChatMessage)
              .toList(growable: false),
        },
      },
    };
  }

  static Map<String, dynamic> _encodeConversationModel(
    ChatConversationModel conversation,
  ) {
    return <String, dynamic>{
      'id': conversation.id,
      'title': conversation.title,
      'preview': conversation.preview,
      'time_label': conversation.timeLabel,
      'avatar': conversation.avatarUrl,
      'user_is_online': conversation.isOnline,
      'is_typing': conversation.isTyping,
      'unread_count': conversation.unreadCount,
      'seen': conversation.isSeen,
      'is_pinned': conversation.isPinned,
      'is_muted': conversation.isMuted,
      'blocked_by_me': conversation.blockedByMe,
      'blocked_me': conversation.blockedMe,
      'can_send_messages': conversation.canSendMessages,
      'target_user_id': conversation.targetUserId,
      'user_id': conversation.targetUserId,
    };
  }

  static Map<String, dynamic> _encodeReadStatus(ChatReadStatusModel status) {
    return <String, dynamic>{
      'conversation_id': status.conversationId,
      'viewer_seen': status.viewerSeen,
      'seen_name_list': status.seenNameList,
      'last_seen_message_id': status.lastSeenMessageId,
      'last_message_id': status.lastMessageId,
      'last_message_user_id': status.lastMessageUserId,
      'user_is_online': status.userIsOnline,
      'user_last_seen': status.userLastSeen,
      'user_last_seen_ago': status.userLastSeenAgo,
      'is_blocked': status.isBlocked,
      'blocked_by_me': status.blockedByMe,
      'blocked_me': status.blockedMe,
      'can_send_messages': status.canSendMessages,
    };
  }

  static Map<String, dynamic> _encodeChatMessage(ChatMessageModel message) {
    return <String, dynamic>{
      'message_id': message.id,
      'conversation_id': message.conversationId,
      'user_id': message.userId,
      'message_decoded': message.text,
      'message_orginal_decoded': message.editableText,
      'image': message.imageUrl,
      'video': message.videoUrl,
      'voice_note': message.voiceNoteUrl,
      'reply_to_message_id': message.replyToMessageId,
      'reply_to_message': message.replyToMessage == null
          ? null
          : _encodeReplyMessage(message.replyToMessage!),
      'forwarded_from_message_id': message.forwardedFromMessageId,
      'forwarded_from_message': message.forwardedFromMessage == null
          ? null
          : _encodeReplyMessage(message.forwardedFromMessage!),
      'sticker_id': message.stickerId,
      'sticker_url': message.stickerUrl,
      'sticker_preview': message.stickerPreviewUrl,
      'sticker_pack': message.stickerPackName,
      'sticker_title': message.stickerTitle,
      'time': message.time,
      'time_ago': message.timeAgo,
      'user_fullname': message.senderName,
      'user_picture': message.senderPicture,
      'product_post_id': message.productPostId,
      'message_type': message.messageType,
      'post_id': message.postId,
      'reel_id': message.reelId,
      'shared_item': message.sharedItem == null
          ? null
          : _encodeSharedAttachment(message.sharedItem!),
      'story_action': message.storyAction == null
          ? null
          : _encodeStoryAction(message.storyAction!),
      'location': message.location == null
          ? null
          : _encodeLocation(message.location!),
      'contact': message.contact == null
          ? null
          : _encodeContact(message.contact!),
      'file': message.fileAttachment == null
          ? null
          : _encodeFileAttachment(message.fileAttachment!),
      'story_id': message.storyId,
      'story_media_id': message.storyMediaId,
      'story_reaction': message.storyReaction,
      'post': <String, dynamic>{
        'og_title': message.productName,
        'og_description': message.productDescription,
        'post_author_url': message.productActionUrl,
        'photos': message.productImageUrl.trim().isEmpty
            ? const <dynamic>[]
            : <Map<String, dynamic>>[
                <String, dynamic>{'source': message.productImageUrl},
              ],
        'product': <String, dynamic>{
          'name': message.productName,
          'price_formatted': message.productPrice,
          'product_download_url': message.productActionUrl,
        },
      },
      'reactions_total_count': message.reactionsTotalCount,
      'i_react': message.iReact,
      'i_reaction': message.myReactionType,
      'reactions': message.reactionCounts.map(
        (key, value) => MapEntry<String, dynamic>(key, value),
      ),
    };
  }

  static Map<String, dynamic> _encodeReplyMessage(
    ChatReplyMessageModel message,
  ) {
    return <String, dynamic>{
      'message_id': message.id,
      'conversation_id': message.conversationId,
      'user_id': message.userId,
      'message_decoded': message.text,
      'image': message.imageUrl,
      'video': message.videoUrl,
      'voice_note': message.voiceNoteUrl,
      'sticker_id': message.stickerId,
      'sticker_url': message.stickerUrl,
      'sticker_preview': message.stickerPreviewUrl,
      'sticker_title': message.stickerTitle,
      'message_type': message.messageType,
      'post_id': message.postId,
      'reel_id': message.reelId,
      'shared_item': message.sharedItem == null
          ? null
          : _encodeSharedAttachment(message.sharedItem!),
      'story_action': message.storyAction == null
          ? null
          : _encodeStoryAction(message.storyAction!),
      'location': message.location == null
          ? null
          : _encodeLocation(message.location!),
      'contact': message.contact == null
          ? null
          : _encodeContact(message.contact!),
      'story_id': message.storyId,
      'story_media_id': message.storyMediaId,
      'story_reaction': message.storyReaction,
      'product_post_id': message.productPostId,
      'post': <String, dynamic>{'og_title': message.productName},
      'time': message.time,
      'user_fullname': message.senderName,
    };
  }

  static Map<String, dynamic> _encodeLocation(ChatLocationModel location) {
    return <String, dynamic>{
      'latitude': location.latitude,
      'longitude': location.longitude,
      'name': location.name,
      'address': location.address,
    };
  }

  static Map<String, dynamic> _encodeContact(
    ChatContactAttachmentModel contact,
  ) {
    return <String, dynamic>{
      'display_name': contact.displayName,
      'phone_number': contact.phoneNumber,
      'phone_label': contact.phoneLabel,
    };
  }

  static Map<String, dynamic> _encodeFileAttachment(
    ChatFileAttachmentModel file,
  ) {
    return <String, dynamic>{
      'source': file.source,
      'url': file.url,
      'download_url': file.downloadUrl,
      'original_name': file.originalName,
      'mime_type': file.mimeType,
      'extension': file.extension,
      'file_size': file.fileSize,
    };
  }

  static Map<String, dynamic> _encodeSharedAttachment(
    ChatSharedAttachmentModel item,
  ) {
    return <String, dynamic>{
      'id': item.id,
      'type': item.type,
      'post_id': item.postId,
      'reel_id': item.reelId,
      'post_type': item.postType,
      'title': item.title,
      'text': item.text,
      'caption': item.caption,
      'source': item.source,
      'file': item.file,
      'thumbnail': item.thumbnail,
      'media_url': item.mediaUrl,
      'url': item.url,
      'mime_type': item.mimeType,
      'author': <String, dynamic>{'user_fullname': item.authorName},
    };
  }

  static Map<String, dynamic> _encodeStoryAction(ChatStoryActionModel action) {
    return <String, dynamic>{
      'action_type': action.actionType,
      'reaction': action.reaction,
      'story': action.story == null
          ? null
          : _encodeStoryAttachment(action.story!),
    };
  }

  static Map<String, dynamic> _encodeStoryAttachment(
    ChatStoryAttachmentModel story,
  ) {
    return <String, dynamic>{
      'story_id': story.storyId,
      'story_media_id': story.storyMediaId,
      'owner_user_id': story.ownerUserId,
      'author': <String, dynamic>{
        'user_fullname': story.authorName,
        'photo': story.authorPhoto,
      },
      'media': <String, dynamic>{
        'type': story.mediaType,
        'src': story.mediaSrc,
        'preview': story.mediaPreview,
        'mime_type': story.mimeType,
      },
      'text': story.text,
      'time': story.time,
    };
  }
}
