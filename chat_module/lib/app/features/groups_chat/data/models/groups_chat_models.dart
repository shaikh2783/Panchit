import 'dart:convert';

import '../../../../../api_config.dart';

class GroupsChatListResponse {
  const GroupsChatListResponse({
    required this.items,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<GroupsChatGroupModel> items;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  factory GroupsChatListResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawItems = (data['items'] as List?) ?? const [];

    return GroupsChatListResponse(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                GroupsChatGroupModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.groupId > 0)
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: _parseNullableInt(data['next_offset']),
      hasMore: _parseBool(data['has_more']),
    );
  }
}

class GroupsChatMessagesResponse {
  const GroupsChatMessagesResponse({
    required this.messages,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<GroupsChatMessageModel> messages;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  factory GroupsChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawMessages = (data['messages'] as List?) ?? const [];

    return GroupsChatMessagesResponse(
      messages: rawMessages
          .whereType<Map>()
          .map(
            (item) => GroupsChatMessageModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.messageId > 0)
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: _parseNullableInt(data['next_offset']),
      hasMore: _parseBool(data['has_more']),
    );
  }
}

class GroupsChatMembersResponse {
  const GroupsChatMembersResponse({
    required this.items,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<GroupsChatMemberModel> items;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  factory GroupsChatMembersResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawItems = (data['items'] as List?) ?? const [];

    return GroupsChatMembersResponse(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                GroupsChatMemberModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.userId > 0)
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: _parseNullableInt(data['next_offset']),
      hasMore: _parseBool(data['has_more']),
    );
  }
}

class GroupsChatEventsResponse {
  const GroupsChatEventsResponse({
    required this.items,
    required this.count,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<GroupsChatEventModel> items;
  final int count;
  final int nextCursor;
  final bool hasMore;

  factory GroupsChatEventsResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawItems = (data['items'] as List?) ?? const [];

    return GroupsChatEventsResponse(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                GroupsChatEventModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.eventId > 0)
          .toList(),
      count: _parseInt(data['count']),
      nextCursor: _parseInt(data['next_cursor']),
      hasMore: _parseBool(data['has_more']),
    );
  }
}

class GroupsChatEventModel {
  const GroupsChatEventModel({
    required this.eventId,
    required this.groupId,
    required this.actionType,
    required this.performedBy,
    required this.targetUserId,
    required this.messageId,
    required this.data,
  });

  final int eventId;
  final int groupId;
  final String actionType;
  final int? performedBy;
  final int? targetUserId;
  final int? messageId;
  final Map<String, dynamic> data;

  factory GroupsChatEventModel.fromJson(Map<String, dynamic> json) {
    return GroupsChatEventModel(
      eventId: _parseInt(json['event_id']),
      groupId: _parseInt(json['group_id']),
      actionType: json['action_type']?.toString() ?? '',
      performedBy: _parseNullableInt(json['performed_by']),
      targetUserId: _parseNullableInt(json['target_user_id']),
      messageId: _parseNullableInt(json['message_id']),
      data: _asMap(json['data']),
    );
  }
}

class GroupsChatReactionAuthorsResponse {
  const GroupsChatReactionAuthorsResponse({
    required this.items,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<GroupsChatReactionAuthorModel> items;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  factory GroupsChatReactionAuthorsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = _asMap(json['data']);
    final rawItems = (data['items'] as List?) ?? const [];

    return GroupsChatReactionAuthorsResponse(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => GroupsChatReactionAuthorModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.userId > 0)
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: _parseNullableInt(data['next_offset']),
      hasMore: _parseBool(data['has_more']),
    );
  }
}

class GroupsChatReactionAuthorModel {
  const GroupsChatReactionAuthorModel({
    required this.userId,
    required this.displayName,
    required this.picture,
    required this.reaction,
    required this.reactionImageUrl,
    required this.reactedAt,
  });

  final int userId;
  final String displayName;
  final String picture;
  final String reaction;
  final String reactionImageUrl;
  final String reactedAt;

  factory GroupsChatReactionAuthorModel.fromJson(Map<String, dynamic> json) {
    final user = GroupsChatUserModel.fromJson(json);
    return GroupsChatReactionAuthorModel(
      userId: user.userId,
      displayName: user.displayName,
      picture: user.picture,
      reaction: json['reaction']?.toString().trim() ?? '',
      reactionImageUrl: _normalizeMediaValue(json['reaction_image_url']),
      reactedAt: json['reacted_at']?.toString() ?? '',
    );
  }
}

class GroupsChatAddMembersResult {
  const GroupsChatAddMembersResult({
    required this.added,
    required this.skipped,
    required this.addedCount,
    required this.skippedCount,
  });

  final List<GroupsChatMemberModel> added;
  final List<Map<String, dynamic>> skipped;
  final int addedCount;
  final int skippedCount;

  factory GroupsChatAddMembersResult.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawAdded = (data['added'] as List?) ?? const [];
    final rawSkipped = (data['skipped'] as List?) ?? const [];

    return GroupsChatAddMembersResult(
      added: rawAdded
          .whereType<Map>()
          .map(
            (item) =>
                GroupsChatMemberModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.userId > 0)
          .toList(),
      skipped: rawSkipped
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      addedCount: _parseInt(data['added_count']),
      skippedCount: _parseInt(data['skipped_count']),
    );
  }
}

class GroupsChatSendInvitationsResult {
  const GroupsChatSendInvitationsResult({
    required this.created,
    required this.skipped,
    required this.createdCount,
    required this.skippedCount,
  });

  final List<Map<String, dynamic>> created;
  final List<Map<String, dynamic>> skipped;
  final int createdCount;
  final int skippedCount;

  factory GroupsChatSendInvitationsResult.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawCreated = (data['created'] as List?) ?? const [];
    final rawSkipped = (data['skipped'] as List?) ?? const [];

    return GroupsChatSendInvitationsResult(
      created: rawCreated
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      skipped: rawSkipped
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      createdCount: _parseInt(data['created_count']),
      skippedCount: _parseInt(data['skipped_count']),
    );
  }
}

class GroupsChatInvitationsResponse {
  const GroupsChatInvitationsResponse({
    required this.items,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<GroupsChatInvitationModel> items;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  factory GroupsChatInvitationsResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawItems = (data['items'] as List?) ?? const [];

    return GroupsChatInvitationsResponse(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => GroupsChatInvitationModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.invitationId > 0)
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: _parseNullableInt(data['next_offset']),
      hasMore: _parseBool(data['has_more']),
    );
  }
}

class GroupsChatInvitationActionResult {
  const GroupsChatInvitationActionResult({
    required this.status,
    this.group,
    this.request,
  });

  final String status;
  final GroupsChatGroupModel? group;
  final GroupsChatInvitationModel? request;

  factory GroupsChatInvitationActionResult.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final group = _asNullableMap(data['group']);
    final request = _asNullableMap(data['request']);

    return GroupsChatInvitationActionResult(
      status: data['status']?.toString() ?? '',
      group: group == null ? null : GroupsChatGroupModel.fromJson(group),
      request: request == null
          ? null
          : GroupsChatInvitationModel.fromJson(request),
    );
  }
}

class GroupsChatInvitationModel {
  const GroupsChatInvitationModel({
    required this.invitationId,
    required this.groupId,
    required this.invitedUserId,
    required this.invitedBy,
    required this.requestType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    required this.respondedAt,
    required this.reviewedBy,
    required this.group,
    required this.inviter,
  });

  final int invitationId;
  final int groupId;
  final int invitedUserId;
  final int invitedBy;
  final String requestType;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String expiresAt;
  final String respondedAt;
  final int? reviewedBy;
  final GroupsChatInvitationGroupModel group;
  final GroupsChatUserModel? inviter;

  bool get isJoinRequest => requestType == 'join_request';
  String get actorName => inviter?.displayName ?? '';

  factory GroupsChatInvitationModel.fromJson(Map<String, dynamic> json) {
    final group = _asMap(json['group']);
    final inviter = _asNullableMap(json['inviter']);

    return GroupsChatInvitationModel(
      invitationId: _parseInt(json['invitation_id']),
      groupId: _parseInt(json['group_id']),
      invitedUserId: _parseInt(json['invited_user_id']),
      invitedBy: _parseInt(json['invited_by']),
      requestType: json['request_type']?.toString() ?? 'invite',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString() ?? '',
      respondedAt: json['responded_at']?.toString() ?? '',
      reviewedBy: _parseNullableInt(json['reviewed_by']),
      group: GroupsChatInvitationGroupModel.fromJson(group),
      inviter: inviter == null ? null : GroupsChatUserModel.fromJson(inviter),
    );
  }
}

class GroupsChatInvitationGroupModel {
  const GroupsChatInvitationGroupModel({
    required this.groupId,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  final int groupId;
  final String name;
  final String imageUrl;
  final String description;

  factory GroupsChatInvitationGroupModel.fromJson(Map<String, dynamic> json) {
    return GroupsChatInvitationGroupModel(
      groupId: _parseInt(json['group_id'] ?? json['id']),
      name: _firstString([json['name'], json['group_name'], json['title']]),
      imageUrl: _normalizeMediaValue(
        _firstString([json['image'], json['group_image']]),
      ),
      description: _firstString([
        json['description'],
        json['group_description'],
      ]),
    );
  }
}

class GroupsChatJoinPreviewModel {
  const GroupsChatJoinPreviewModel({
    required this.token,
    required this.joinLink,
    required this.status,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.memberCount,
  });

  final String token;
  final String joinLink;
  final String status;
  final String name;
  final String imageUrl;
  final String description;
  final int memberCount;

  bool get isAlreadyMember => status == 'already_member';
  bool get isBanned => status == 'banned';
  bool get isPendingRequest => status == 'pending';

  factory GroupsChatJoinPreviewModel.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final group = _asMap(data['group']);

    return GroupsChatJoinPreviewModel(
      token: data['token']?.toString() ?? '',
      joinLink: data['join_link']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      name: _firstString([group['name'], group['group_name'], group['title']]),
      imageUrl: _normalizeMediaValue(
        _firstString([group['image'], group['group_image']]),
      ),
      description: _firstString([
        group['description'],
        group['group_description'],
      ]),
      memberCount: _parseInt(group['member_count']),
    );
  }
}

class GroupsChatGroupModel {
  const GroupsChatGroupModel({
    required this.groupId,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.createdBy,
    required this.groupType,
    required this.joinToken,
    required this.joinLink,
    required this.messagePermission,
    required this.editPermission,
    required this.addMembersPermission,
    required this.memberListPermission,
    required this.reactionViewPermission,
    required this.joinLinkPermission,
    required this.memberCount,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.currentMember,
    required this.preferences,
    required this.lastMessage,
  });

  final int groupId;
  final String name;
  final String imageUrl;
  final String description;
  final int createdBy;
  final String groupType;
  final String joinToken;
  final String joinLink;
  final String messagePermission;
  final String editPermission;
  final String addMembersPermission;
  final String memberListPermission;
  final String reactionViewPermission;
  final String joinLinkPermission;
  final int memberCount;
  final int unreadCount;
  final String createdAt;
  final String updatedAt;
  final GroupsChatCurrentMemberModel? currentMember;
  final GroupsChatPreferencesModel preferences;
  final GroupsChatMessagePreviewModel? lastMessage;

  bool get isMuted => preferences.isMuted;
  bool get canSendMessages => currentMember?.canSendMessages ?? false;
  bool get isCurrentMemberMutedByAdmin {
    final member = currentMember;
    if (member == null) {
      return false;
    }
    if (member.isMutedByAdmin) {
      return true;
    }
    return !member.canSendMessages && messagePermission != 'admins';
  }

  String get role => currentMember?.role ?? 'member';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'owner' || role == 'admin';
  bool get canViewMembers => isAdmin || memberListPermission == 'members';
  bool get canViewReactionAuthors =>
      isAdmin || reactionViewPermission == 'members';
  bool get canCopyJoinLink =>
      joinLink.trim().isNotEmpty &&
      (isAdmin || joinLinkPermission == 'members');
  bool get canManageMembers => currentMember?.canManageMembers ?? false;
  bool get canManageAdmins => currentMember?.canManageAdmins ?? false;
  bool get canManageAdminRoles => currentMember?.canManageAdminRoles ?? false;
  bool get canManageAdminPermissions =>
      currentMember?.canManageAdminPermissions ?? false;
  bool get canDeleteMessages => currentMember?.canDeleteMessages ?? false;
  bool get canMuteMembers => currentMember?.canMuteMembers ?? false;
  bool get canManageJoinLink => currentMember?.canManageJoinLink ?? false;

  String get previewText {
    final message = lastMessage;
    if (message == null) {
      return '';
    }
    return message.previewText;
  }

  String get timeLabel {
    final messageTime = lastMessage?.timeLabel ?? '';
    if (messageTime.isNotEmpty) {
      return messageTime;
    }
    return updatedAt;
  }

  bool get canEditGroup => currentMember?.canEditGroup ?? false;
  bool get canAddMembers => canManageMembers;

  factory GroupsChatGroupModel.fromJson(Map<String, dynamic> json) {
    final currentMember = _asNullableMap(json['current_member']);
    final preferences = _asMap(json['preferences']);
    final lastMessage = _asNullableMap(json['last_message']);

    return GroupsChatGroupModel(
      groupId: _parseInt(json['group_id'] ?? json['id']),
      name: _firstString([json['name'], json['group_name'], json['title']]),
      imageUrl: _firstString([
        json['image'],
        json['group_image'],
        json['avatar'],
        json['picture'],
      ]),
      description: _firstString([
        json['description'],
        json['group_description'],
      ]),
      createdBy: _parseInt(json['created_by']),
      groupType: json['group_type']?.toString() ?? 'private',
      joinToken: json['join_token']?.toString() ?? '',
      joinLink: json['join_link']?.toString() ?? '',
      messagePermission: json['message_permission']?.toString() ?? 'members',
      editPermission: json['edit_permission']?.toString() ?? 'admins',
      addMembersPermission:
          json['add_members_permission']?.toString() ?? 'admins',
      memberListPermission:
          json['member_list_permission']?.toString() ?? 'members',
      reactionViewPermission:
          json['reaction_view_permission']?.toString() ?? 'members',
      joinLinkPermission: json['join_link_permission']?.toString() ?? 'members',
      memberCount: _parseInt(json['member_count']),
      unreadCount: _parseInt(json['unread_count']),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      currentMember: currentMember == null
          ? null
          : GroupsChatCurrentMemberModel.fromJson(currentMember),
      preferences: GroupsChatPreferencesModel.fromJson(preferences),
      lastMessage: lastMessage == null
          ? null
          : GroupsChatMessagePreviewModel.fromJson(lastMessage),
    );
  }

  GroupsChatGroupModel copyWith({
    String? name,
    String? imageUrl,
    String? description,
    String? joinToken,
    String? joinLink,
    String? messagePermission,
    String? editPermission,
    String? addMembersPermission,
    String? memberListPermission,
    String? reactionViewPermission,
    String? joinLinkPermission,
    int? memberCount,
    int? unreadCount,
    GroupsChatCurrentMemberModel? currentMember,
    GroupsChatPreferencesModel? preferences,
    GroupsChatMessagePreviewModel? lastMessage,
  }) {
    return GroupsChatGroupModel(
      groupId: groupId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdBy: createdBy,
      groupType: groupType,
      joinToken: joinToken ?? this.joinToken,
      joinLink: joinLink ?? this.joinLink,
      messagePermission: messagePermission ?? this.messagePermission,
      editPermission: editPermission ?? this.editPermission,
      addMembersPermission: addMembersPermission ?? this.addMembersPermission,
      memberListPermission: memberListPermission ?? this.memberListPermission,
      reactionViewPermission:
          reactionViewPermission ?? this.reactionViewPermission,
      joinLinkPermission: joinLinkPermission ?? this.joinLinkPermission,
      memberCount: memberCount ?? this.memberCount,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      currentMember: currentMember ?? this.currentMember,
      preferences: preferences ?? this.preferences,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class GroupsChatMessageModel {
  const GroupsChatMessageModel({
    required this.messageId,
    required this.groupId,
    required this.senderId,
    required this.messageType,
    required this.message,
    required this.mediaUrl,
    required this.mediaSource,
    required this.mediaMeta,
    required this.replyToMessageId,
    required this.isDeleted,
    required this.deletedAt,
    required this.editedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.timeAgo,
    required this.sender,
    required this.readByCount,
    required this.reactionsTotalCount,
    required this.iReact,
    required this.topReactionType,
    required this.myReactionType,
    required this.reactionCounts,
  });

  final int messageId;
  final int groupId;
  final int senderId;
  final String messageType;
  final String message;
  final String mediaUrl;
  final String mediaSource;
  final Map<String, dynamic> mediaMeta;
  final int? replyToMessageId;
  final bool isDeleted;
  final String deletedAt;
  final String editedAt;
  final String createdAt;
  final String updatedAt;
  final String timeAgo;
  final GroupsChatUserModel? sender;
  final int readByCount;
  final int reactionsTotalCount;
  final bool iReact;
  final String topReactionType;
  final String myReactionType;
  final Map<String, int> reactionCounts;

  String get timeLabel => timeAgo.isNotEmpty ? timeAgo : createdAt;
  String get senderName => sender?.displayName ?? '';
  bool get hasMedia => mediaBestUrl.isNotEmpty;
  bool get hasReactions => reactionsTotalCount > 0;
  String get displayedReactionType {
    if (iReact && myReactionType.trim().isNotEmpty) {
      return myReactionType.trim();
    }
    return topReactionType.trim();
  }

  String get mediaBestUrl {
    for (final value in <String>[mediaUrl, mediaSource]) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String get attachmentName {
    for (final key in <String>[
      'original_name',
      'file_name',
      'name',
      'display_name',
    ]) {
      final value = mediaMeta[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    final url = mediaBestUrl;
    if (url.isEmpty) {
      return '';
    }
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    return segments.isEmpty ? url : segments.last;
  }

  int get attachmentSize => _parseInt(mediaMeta['file_size']);
  String get attachmentMimeType =>
      mediaMeta['mime_type']?.toString().trim().toLowerCase() ?? '';

  factory GroupsChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = _asNullableMap(json['sender']);
    final mediaMeta = _asMap(json['media_meta']);
    final reactionCounts = _normalizeReactionCounts(_asMap(json['reactions']));
    final topReactionType = _resolveTopReactionType(reactionCounts);
    final didReact = _parseBool(json['i_react']);
    final myReactionType =
        json['i_reaction']?.toString().trim() ??
        (didReact ? topReactionType : '');
    return GroupsChatMessageModel(
      messageId: _parseInt(json['message_id']),
      groupId: _parseInt(json['group_id']),
      senderId: _parseInt(json['sender_id']),
      messageType: json['message_type']?.toString() ?? 'text',
      message: json['message']?.toString() ?? '',
      mediaUrl: _normalizeMediaValue(json['media_url']),
      mediaSource: _normalizeMediaValue(json['media_source']),
      mediaMeta: mediaMeta,
      replyToMessageId: _parseNullableInt(json['reply_to_message_id']),
      isDeleted: _parseBool(json['is_deleted']),
      deletedAt: json['deleted_at']?.toString() ?? '',
      editedAt: json['edited_at']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      sender: sender == null ? null : GroupsChatUserModel.fromJson(sender),
      readByCount: _parseInt(json['read_by_count']),
      reactionsTotalCount: _parseInt(json['reactions_total_count']),
      iReact: didReact,
      topReactionType: topReactionType,
      myReactionType: myReactionType,
      reactionCounts: reactionCounts,
    );
  }

  GroupsChatMessageModel copyWith({
    int? reactionsTotalCount,
    bool? iReact,
    String? topReactionType,
    String? myReactionType,
    Map<String, int>? reactionCounts,
  }) {
    return GroupsChatMessageModel(
      messageId: messageId,
      groupId: groupId,
      senderId: senderId,
      messageType: messageType,
      message: message,
      mediaUrl: mediaUrl,
      mediaSource: mediaSource,
      mediaMeta: mediaMeta,
      replyToMessageId: replyToMessageId,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      editedAt: editedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      timeAgo: timeAgo,
      sender: sender,
      readByCount: readByCount,
      reactionsTotalCount: reactionsTotalCount ?? this.reactionsTotalCount,
      iReact: iReact ?? this.iReact,
      topReactionType: topReactionType ?? this.topReactionType,
      myReactionType: myReactionType ?? this.myReactionType,
      reactionCounts: reactionCounts ?? this.reactionCounts,
    );
  }
}

class GroupsChatCurrentMemberModel {
  const GroupsChatCurrentMemberModel({
    required this.role,
    required this.status,
    required this.canSendMessages,
    required this.isMutedByAdmin,
    required this.mutedUntil,
    required this.joinedAt,
    required this.adminPermissions,
  });

  final String role;
  final String status;
  final bool canSendMessages;
  final bool isMutedByAdmin;
  final String mutedUntil;
  final String joinedAt;
  final GroupsChatAdminPermissionsModel adminPermissions;

  bool get canManageMembers => adminPermissions.canManageMembers;
  bool get canManageAdmins => adminPermissions.canManageAdmins;
  bool get canManageAdminRoles => adminPermissions.canManageAdminRoles;
  bool get canManageAdminPermissions =>
      adminPermissions.canManageAdminPermissions;
  bool get canEditGroup => adminPermissions.canEditGroup;
  bool get canDeleteMessages => adminPermissions.canDeleteMessages;
  bool get canMuteMembers => adminPermissions.canMuteMembers;
  bool get canManageJoinLink => adminPermissions.canManageJoinLink;

  factory GroupsChatCurrentMemberModel.fromJson(Map<String, dynamic> json) {
    final role = json['role']?.toString() ?? 'member';
    return GroupsChatCurrentMemberModel(
      role: role,
      status: json['status']?.toString() ?? '',
      canSendMessages: _parseBool(json['can_send_messages']),
      isMutedByAdmin: _parseBool(json['is_muted_by_admin']),
      mutedUntil: json['muted_until']?.toString() ?? '',
      joinedAt: json['joined_at']?.toString() ?? '',
      adminPermissions: GroupsChatAdminPermissionsModel.fromJson(
        _asNullableMap(json['admin_permissions']),
        role: role,
      ),
    );
  }
}

class GroupsChatAdminPermissionsModel {
  const GroupsChatAdminPermissionsModel({
    required this.canManageMembers,
    required this.canManageAdmins,
    required this.canManageAdminRoles,
    required this.canManageAdminPermissions,
    required this.canEditGroup,
    required this.canDeleteMessages,
    required this.canMuteMembers,
    required this.canManageJoinLink,
  });

  final bool canManageMembers;
  final bool canManageAdmins;
  final bool canManageAdminRoles;
  final bool canManageAdminPermissions;
  final bool canEditGroup;
  final bool canDeleteMessages;
  final bool canMuteMembers;
  final bool canManageJoinLink;

  factory GroupsChatAdminPermissionsModel.fromJson(
    Map<String, dynamic>? json, {
    required String role,
  }) {
    final isAdminRole = role == 'owner' || role == 'admin';
    bool read(String key, {String? fallbackKey}) {
      if (json == null || !json.containsKey(key)) {
        if (json != null &&
            fallbackKey != null &&
            json.containsKey(fallbackKey)) {
          return _parseBool(json[fallbackKey]);
        }
        return isAdminRole;
      }
      return _parseBool(json[key]);
    }

    return GroupsChatAdminPermissionsModel(
      canManageMembers: read('can_manage_members'),
      canManageAdmins: read('can_manage_admins'),
      canManageAdminRoles: read(
        'can_manage_admin_roles',
        fallbackKey: 'can_manage_admins',
      ),
      canManageAdminPermissions: read(
        'can_manage_admin_permissions',
        fallbackKey: 'can_manage_admins',
      ),
      canEditGroup: read('can_edit_group'),
      canDeleteMessages: read('can_delete_messages'),
      canMuteMembers: read('can_mute_members'),
      canManageJoinLink: read('can_manage_join_link'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'can_manage_members': canManageMembers,
      'can_manage_admins': canManageAdminRoles && canManageAdminPermissions,
      'can_manage_admin_roles': canManageAdminRoles,
      'can_manage_admin_permissions': canManageAdminPermissions,
      'can_edit_group': canEditGroup,
      'can_delete_messages': canDeleteMessages,
      'can_mute_members': canMuteMembers,
      'can_manage_join_link': canManageJoinLink,
    };
  }

  GroupsChatAdminPermissionsModel copyWith({
    bool? canManageMembers,
    bool? canManageAdmins,
    bool? canManageAdminRoles,
    bool? canManageAdminPermissions,
    bool? canEditGroup,
    bool? canDeleteMessages,
    bool? canMuteMembers,
    bool? canManageJoinLink,
  }) {
    return GroupsChatAdminPermissionsModel(
      canManageMembers: canManageMembers ?? this.canManageMembers,
      canManageAdmins: canManageAdmins ?? this.canManageAdmins,
      canManageAdminRoles: canManageAdminRoles ?? this.canManageAdminRoles,
      canManageAdminPermissions:
          canManageAdminPermissions ?? this.canManageAdminPermissions,
      canEditGroup: canEditGroup ?? this.canEditGroup,
      canDeleteMessages: canDeleteMessages ?? this.canDeleteMessages,
      canMuteMembers: canMuteMembers ?? this.canMuteMembers,
      canManageJoinLink: canManageJoinLink ?? this.canManageJoinLink,
    );
  }
}

class GroupsChatPreferencesModel {
  const GroupsChatPreferencesModel({
    required this.isMuted,
    required this.isMutedAlways,
    required this.mutedUntil,
  });

  final bool isMuted;
  final bool isMutedAlways;
  final String mutedUntil;

  factory GroupsChatPreferencesModel.fromJson(Map<String, dynamic> json) {
    return GroupsChatPreferencesModel(
      isMuted: _parseBool(json['is_muted']),
      isMutedAlways: _parseBool(json['is_muted_always']),
      mutedUntil: json['muted_until']?.toString() ?? '',
    );
  }

  GroupsChatPreferencesModel copyWith({
    bool? isMuted,
    bool? isMutedAlways,
    String? mutedUntil,
  }) {
    return GroupsChatPreferencesModel(
      isMuted: isMuted ?? this.isMuted,
      isMutedAlways: isMutedAlways ?? this.isMutedAlways,
      mutedUntil: mutedUntil ?? this.mutedUntil,
    );
  }
}

class GroupsChatMemberModel {
  const GroupsChatMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.mutedUntil,
    required this.canSendMessages,
    required this.isMutedByAdmin,
    required this.adminPermissions,
    required this.user,
  });

  final int id;
  final int groupId;
  final int userId;
  final String role;
  final String status;
  final String joinedAt;
  final String mutedUntil;
  final bool canSendMessages;
  final bool isMutedByAdmin;
  final GroupsChatAdminPermissionsModel adminPermissions;
  final GroupsChatUserModel? user;

  String get displayName => user?.displayName ?? '';
  String get picture => user?.picture ?? '';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'owner' || role == 'admin';
  bool get canManageMembers => adminPermissions.canManageMembers;
  bool get canManageAdmins => adminPermissions.canManageAdmins;
  bool get canManageAdminRoles => adminPermissions.canManageAdminRoles;
  bool get canManageAdminPermissions =>
      adminPermissions.canManageAdminPermissions;
  bool get canEditGroup => adminPermissions.canEditGroup;
  bool get canDeleteMessages => adminPermissions.canDeleteMessages;
  bool get canMuteMembers => adminPermissions.canMuteMembers;
  bool get canManageJoinLink => adminPermissions.canManageJoinLink;

  factory GroupsChatMemberModel.fromJson(Map<String, dynamic> json) {
    final user = _asNullableMap(json['user']);
    final role = json['role']?.toString() ?? 'member';
    return GroupsChatMemberModel(
      id: _parseInt(json['id']),
      groupId: _parseInt(json['group_id']),
      userId: _parseInt(json['user_id']),
      role: role,
      status: json['status']?.toString() ?? '',
      joinedAt: json['joined_at']?.toString() ?? '',
      mutedUntil: json['muted_until']?.toString() ?? '',
      canSendMessages: _parseBool(json['can_send_messages']),
      isMutedByAdmin:
          _parseBool(json['is_muted_by_admin']) ||
          !_parseBool(json['can_send_messages']),
      adminPermissions: GroupsChatAdminPermissionsModel.fromJson(
        _asNullableMap(json['admin_permissions']),
        role: role,
      ),
      user: user == null ? null : GroupsChatUserModel.fromJson(user),
    );
  }

  GroupsChatMemberModel copyWith({
    String? role,
    String? status,
    bool? canSendMessages,
    bool? isMutedByAdmin,
    GroupsChatAdminPermissionsModel? adminPermissions,
  }) {
    return GroupsChatMemberModel(
      id: id,
      groupId: groupId,
      userId: userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt,
      mutedUntil: mutedUntil,
      canSendMessages: canSendMessages ?? this.canSendMessages,
      isMutedByAdmin: isMutedByAdmin ?? this.isMutedByAdmin,
      adminPermissions: adminPermissions ?? this.adminPermissions,
      user: user,
    );
  }
}

class GroupsChatMessagePreviewModel {
  const GroupsChatMessagePreviewModel({
    required this.messageId,
    required this.senderId,
    required this.messageType,
    required this.message,
    required this.mediaUrl,
    required this.createdAt,
    required this.timeAgo,
    required this.sender,
  });

  final int messageId;
  final int senderId;
  final String messageType;
  final String message;
  final String mediaUrl;
  final String createdAt;
  final String timeAgo;
  final GroupsChatUserModel? sender;

  String get previewText {
    if (message.trim().isNotEmpty) {
      final senderName = sender?.displayName ?? '';
      return senderName.isEmpty
          ? message.trim()
          : '$senderName: ${message.trim()}';
    }
    switch (messageType) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Voice message';
      case 'file':
        return 'File';
      default:
        return messageType.isEmpty ? '' : messageType;
    }
  }

  String get timeLabel => timeAgo.isNotEmpty ? timeAgo : createdAt;

  factory GroupsChatMessagePreviewModel.fromJson(Map<String, dynamic> json) {
    final sender = _asNullableMap(json['sender']);
    return GroupsChatMessagePreviewModel(
      messageId: _parseInt(json['message_id']),
      senderId: _parseInt(json['sender_id']),
      messageType: json['message_type']?.toString() ?? 'text',
      message: json['message']?.toString() ?? '',
      mediaUrl: _normalizeMediaValue(json['media_url']),
      createdAt: json['created_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      sender: sender == null ? null : GroupsChatUserModel.fromJson(sender),
    );
  }
}

class GroupsChatUserModel {
  const GroupsChatUserModel({
    required this.userId,
    required this.userName,
    required this.fullName,
    required this.picture,
  });

  final int userId;
  final String userName;
  final String fullName;
  final String picture;

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    return userName.trim();
  }

  factory GroupsChatUserModel.fromJson(Map<String, dynamic> json) {
    return GroupsChatUserModel(
      userId: _parseInt(json['user_id']),
      userName: json['user_name']?.toString() ?? '',
      fullName: _firstString([
        json['user_fullname'],
        [
          json['user_firstname']?.toString() ?? '',
          json['user_lastname']?.toString() ?? '',
        ].where((part) => part.trim().isNotEmpty).join(' '),
      ]),
      picture: json['user_picture']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  final text = value?.toString().trim() ?? '';
  if (text.startsWith('{') && text.endsWith('}')) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return <String, dynamic>{};
    }
  }
  return <String, dynamic>{};
}

Map<String, dynamic>? _asNullableMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _firstString(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

String _normalizeMediaValue(dynamic value) {
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
  if (raw.startsWith('messangr_groups_chat/')) {
    return '${ApiConfig.baseUrl}/content/uploads/$raw';
  }
  if (raw.startsWith('photos/') ||
      raw.startsWith('videos/') ||
      raw.startsWith('sounds/') ||
      raw.startsWith('files/')) {
    return _resolveUploadUrl(raw);
  }
  return raw;
}

String _resolveUploadUrl(String raw) {
  final trimmedBaseUrl = ApiConfig.baseUrl.trim().replaceFirst(
    RegExp(r'/+$'),
    '',
  );
  return '$trimmedBaseUrl/content/uploads/${raw.replaceFirst(RegExp(r'^/+'), '')}';
}

Map<String, int> _normalizeReactionCounts(Map<String, dynamic> reactions) {
  final normalized = <String, int>{};
  for (final entry in reactions.entries) {
    final key = entry.key.trim();
    final count = _parseInt(entry.value);
    if (key.isEmpty || count <= 0) {
      continue;
    }
    normalized[key] = count;
  }
  return normalized;
}

String _resolveTopReactionType(Map<String, int> reactions) {
  var topType = '';
  var topCount = -1;
  for (final entry in reactions.entries) {
    if (entry.value > topCount) {
      topCount = entry.value;
      topType = entry.key;
    }
  }
  return topType;
}

bool _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}
