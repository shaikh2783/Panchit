import 'dart:typed_data';

import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/api/api_endpoints.dart';
import '../../../chat/data/models/chat_report_models.dart';
import '../../../chat/data/models/chat_reaction_types_response.dart';
import '../../utils/groups_chat_logger.dart';
import '../models/groups_chat_models.dart';

class GroupsChatService {
  GroupsChatService(this._apiClient);

  final ChatModuleApiClient _apiClient;

  Future<Map<String, dynamic>> fetchManifest() {
    GroupsChatLogger.log('service', 'fetchManifest');
    return _apiClient.get(ApiEndpoints.groupsChatManifest, authenticated: true);
  }

  Future<ChatReactionTypesResponse> fetchReactionTypes() async {
    GroupsChatLogger.log('service', 'fetchReactionTypes');
    final response = await _apiClient.get(
      ApiEndpoints.groupsChatReactionTypes,
      authenticated: true,
    );
    return ChatReactionTypesResponse.fromJson(response);
  }

  Future<ChatReportCategoriesResponse> fetchReportCategories() async {
    GroupsChatLogger.log('service', 'fetchReportCategories');
    final response = await _apiClient.get(
      '/api-addon-messangr/groups-chat/report/categories',
      authenticated: true,
    );
    return ChatReportCategoriesResponse.fromJson(response);
  }

  Future<GroupsChatListResponse> fetchGroups({int? offset}) async {
    GroupsChatLogger.log('service', 'fetchGroups offset=${offset ?? 0}');
    final response = await _apiClient.get(
      ApiEndpoints.groupsChatGroups,
      authenticated: true,
      queryParameters: offset == null
          ? null
          : <String, dynamic>{'offset': offset},
    );
    final result = GroupsChatListResponse.fromJson(response);
    GroupsChatLogger.log(
      'service',
      'fetchGroups success count=${result.items.length} hasMore=${result.hasMore}',
    );
    return result;
  }

  Future<GroupsChatGroupModel> createGroup({
    required String name,
    String? description,
  }) async {
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim() ?? '';
    GroupsChatLogger.log(
      'service',
      'createGroup name="$trimmedName" hasDescription=${trimmedDescription.isNotEmpty}',
    );
    final response = await _apiClient.post(
      ApiEndpoints.groupsChatGroups,
      authenticated: true,
      body: <String, dynamic>{
        'name': trimmedName,
        if (trimmedDescription.isNotEmpty) 'description': trimmedDescription,
      },
    );
    final data = response['data'];
    final group = data is Map ? data['group'] : null;
    if (group is Map) {
      final created = GroupsChatGroupModel.fromJson(
        Map<String, dynamic>.from(group),
      );
      GroupsChatLogger.log(
        'service',
        'createGroup success groupId=${created.groupId} name="${created.name}"',
      );
      return created;
    }
    throw const ApiException('Unable to create group');
  }

  Future<GroupsChatGroupModel> fetchGroupDetails({required int groupId}) async {
    GroupsChatLogger.log('service', 'fetchGroupDetails groupId=$groupId');
    final response = await _apiClient.get(
      '${ApiEndpoints.groupsChatGroups}/$groupId',
      authenticated: true,
    );
    final data = response['data'];
    final group = data is Map ? data['group'] : null;
    if (group is Map) {
      return GroupsChatGroupModel.fromJson(Map<String, dynamic>.from(group));
    }
    throw const ApiException('Unable to load group details');
  }

  Future<GroupsChatGroupModel> updateGroup({
    required int groupId,
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim() ?? '';
    final trimmedImageUrl = imageUrl?.trim();
    GroupsChatLogger.log(
      'service',
      'updateGroup groupId=$groupId name="$trimmedName" hasDescription=${trimmedDescription.isNotEmpty} hasImage=${trimmedImageUrl?.isNotEmpty == true}',
    );
    final body = <String, dynamic>{
      'name': trimmedName,
      'description': trimmedDescription,
    };
    if (trimmedImageUrl != null) {
      body['image'] = trimmedImageUrl;
    }
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId',
      authenticated: true,
      body: body,
    );
    final data = response['data'];
    final group = data is Map ? data['group'] : null;
    if (group is Map) {
      return GroupsChatGroupModel.fromJson(Map<String, dynamic>.from(group));
    }
    throw const ApiException('Unable to update group');
  }

  Future<void> deleteGroup({required int groupId}) async {
    GroupsChatLogger.log('service', 'deleteGroup groupId=$groupId');
    await _apiClient.delete(
      '${ApiEndpoints.groupsChatGroups}/$groupId',
      authenticated: true,
    );
  }

  Future<String> reportGroup({
    required int groupId,
    required int categoryId,
    String? reason,
  }) async {
    final trimmedReason = reason?.trim() ?? '';
    GroupsChatLogger.log(
      'service',
      'reportGroup groupId=$groupId categoryId=$categoryId hasReason=${trimmedReason.isNotEmpty}',
    );
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/report',
      authenticated: true,
      body: <String, dynamic>{
        'category_id': categoryId,
        'category': categoryId,
        if (trimmedReason.isNotEmpty) 'reason': trimmedReason,
      },
    );
    final message = response['message']?.toString().trim() ?? '';
    return message.isEmpty ? 'Your report has been submitted' : message;
  }

  Future<GroupsChatMembersResponse> fetchMembers({
    required int groupId,
    int? offset,
    int? limit,
    int? userId,
  }) async {
    GroupsChatLogger.log(
      'service',
      'fetchMembers groupId=$groupId offset=${offset ?? 0} userId=${userId ?? '-'}',
    );
    final queryParameters = <String, dynamic>{'status': 'active'};
    if (offset != null) {
      queryParameters['offset'] = offset;
    }
    if (limit != null) {
      queryParameters['limit'] = limit;
    }
    if (userId != null && userId > 0) {
      queryParameters['user_id'] = userId;
    }
    final response = await _apiClient.get(
      '${ApiEndpoints.groupsChatGroups}/$groupId/members',
      authenticated: true,
      queryParameters: queryParameters,
    );
    return GroupsChatMembersResponse.fromJson(response);
  }

  Future<GroupsChatMemberModel?> fetchMember({
    required int groupId,
    required int userId,
  }) async {
    final response = await fetchMembers(
      groupId: groupId,
      userId: userId,
      limit: 1,
    );
    return response.items.isEmpty ? null : response.items.first;
  }

  Future<GroupsChatAddMembersResult> addMembers({
    required int groupId,
    required List<int> userIds,
  }) async {
    GroupsChatLogger.log(
      'service',
      'addMembers groupId=$groupId count=${userIds.length}',
    );
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/members',
      authenticated: true,
      body: <String, dynamic>{'user_ids': userIds},
    );
    return GroupsChatAddMembersResult.fromJson(response);
  }

  Future<GroupsChatSendInvitationsResult> sendInvitations({
    required int groupId,
    required List<int> userIds,
  }) async {
    GroupsChatLogger.log(
      'service',
      'sendInvitations groupId=$groupId count=${userIds.length}',
    );
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/invitations',
      authenticated: true,
      body: <String, dynamic>{'user_ids': userIds},
    );
    return GroupsChatSendInvitationsResult.fromJson(response);
  }

  Future<GroupsChatInvitationsResponse> fetchPendingInvitations({
    int? offset,
  }) async {
    GroupsChatLogger.log(
      'service',
      'fetchPendingInvitations offset=${offset ?? 0}',
    );
    final response = await _apiClient.get(
      '/api-addon-messangr/groups-chat/invitations/pending',
      authenticated: true,
      queryParameters: offset == null
          ? null
          : <String, dynamic>{'offset': offset},
    );
    return GroupsChatInvitationsResponse.fromJson(response);
  }

  Future<GroupsChatInvitationActionResult> acceptInvitation({
    required int invitationId,
  }) async {
    GroupsChatLogger.log(
      'service',
      'acceptInvitation invitationId=$invitationId',
    );
    final response = await _apiClient.post(
      '/api-addon-messangr/groups-chat/invitations/$invitationId/accept',
      authenticated: true,
    );
    return GroupsChatInvitationActionResult.fromJson(response);
  }

  Future<GroupsChatInvitationActionResult> rejectInvitation({
    required int invitationId,
  }) async {
    GroupsChatLogger.log(
      'service',
      'rejectInvitation invitationId=$invitationId',
    );
    final response = await _apiClient.post(
      '/api-addon-messangr/groups-chat/invitations/$invitationId/reject',
      authenticated: true,
    );
    return GroupsChatInvitationActionResult.fromJson(response);
  }

  Future<GroupsChatInvitationActionResult> requestJoin({
    String? joinToken,
    int? groupId,
  }) async {
    final token = joinToken?.trim() ?? '';
    GroupsChatLogger.log(
      'service',
      'requestJoin token=${token.isEmpty ? '-' : 'set'} groupId=${groupId ?? '-'}',
    );
    if (token.isEmpty && (groupId ?? 0) <= 0) {
      throw const ApiException('Invalid group join link');
    }
    final path = token.isNotEmpty
        ? '/api-addon-messangr/groups-chat/join/${Uri.encodeComponent(token)}/request'
        : '${ApiEndpoints.groupsChatGroups}/$groupId/join-requests';
    final response = await _apiClient.post(path, authenticated: true);
    return GroupsChatInvitationActionResult.fromJson(response);
  }

  Future<GroupsChatJoinPreviewModel> fetchJoinPreview({
    required String joinToken,
  }) async {
    final token = joinToken.trim();
    GroupsChatLogger.log(
      'service',
      'fetchJoinPreview token=${token.isEmpty ? '-' : 'set'}',
    );
    if (token.isEmpty) {
      throw const ApiException('Invalid group join link');
    }
    final response = await _apiClient.get(
      '/api-addon-messangr/groups-chat/join/${Uri.encodeComponent(token)}',
      authenticated: true,
    );
    return GroupsChatJoinPreviewModel.fromJson(response);
  }

  Future<GroupsChatInvitationsResponse> fetchJoinRequests({
    required int groupId,
    int? offset,
  }) async {
    GroupsChatLogger.log(
      'service',
      'fetchJoinRequests groupId=$groupId offset=${offset ?? 0}',
    );
    final response = await _apiClient.get(
      '${ApiEndpoints.groupsChatGroups}/$groupId/join-requests',
      authenticated: true,
      queryParameters: offset == null
          ? null
          : <String, dynamic>{'offset': offset},
    );
    return GroupsChatInvitationsResponse.fromJson(response);
  }

  Future<GroupsChatInvitationActionResult> approveJoinRequest({
    required int invitationId,
  }) async {
    GroupsChatLogger.log(
      'service',
      'approveJoinRequest invitationId=$invitationId',
    );
    final response = await _apiClient.post(
      '/api-addon-messangr/groups-chat/join-requests/$invitationId/approve',
      authenticated: true,
    );
    return GroupsChatInvitationActionResult.fromJson(response);
  }

  Future<GroupsChatInvitationActionResult> rejectJoinRequest({
    required int invitationId,
  }) async {
    GroupsChatLogger.log(
      'service',
      'rejectJoinRequest invitationId=$invitationId',
    );
    final response = await _apiClient.post(
      '/api-addon-messangr/groups-chat/join-requests/$invitationId/reject',
      authenticated: true,
    );
    return GroupsChatInvitationActionResult.fromJson(response);
  }

  Future<void> removeMember({required int groupId, required int userId}) async {
    GroupsChatLogger.log(
      'service',
      'removeMember groupId=$groupId userId=$userId',
    );
    await _apiClient.delete(
      '${ApiEndpoints.groupsChatGroups}/$groupId/members/$userId',
      authenticated: true,
    );
  }

  Future<void> leaveGroup({required int groupId}) async {
    GroupsChatLogger.log('service', 'leaveGroup groupId=$groupId');
    await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/leave',
      authenticated: true,
    );
  }

  Future<void> makeAdmin({required int groupId, required int userId}) async {
    GroupsChatLogger.log(
      'service',
      'makeAdmin groupId=$groupId userId=$userId',
    );
    await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/members/$userId/admin',
      authenticated: true,
    );
  }

  Future<void> removeAdmin({required int groupId, required int userId}) async {
    GroupsChatLogger.log(
      'service',
      'removeAdmin groupId=$groupId userId=$userId',
    );
    await _apiClient.delete(
      '${ApiEndpoints.groupsChatGroups}/$groupId/members/$userId/admin',
      authenticated: true,
    );
  }

  Future<GroupsChatMemberModel> updateAdminPermissions({
    required int groupId,
    required int userId,
    required GroupsChatAdminPermissionsModel permissions,
  }) async {
    GroupsChatLogger.log(
      'service',
      'updateAdminPermissions groupId=$groupId userId=$userId',
    );
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/members/$userId/permissions',
      authenticated: true,
      body: permissions.toJson(),
    );
    final data = response['data'];
    final member = data is Map ? data['member'] : null;
    if (member is Map) {
      return GroupsChatMemberModel.fromJson(Map<String, dynamic>.from(member));
    }
    throw const ApiException('Unable to update admin permissions');
  }

  Future<void> muteMember({required int groupId, required int userId}) async {
    GroupsChatLogger.log(
      'service',
      'muteMember groupId=$groupId userId=$userId',
    );
    await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/members/$userId/mute',
      authenticated: true,
      body: const <String, dynamic>{'duration': 'always'},
    );
  }

  Future<void> unmuteMember({required int groupId, required int userId}) async {
    GroupsChatLogger.log(
      'service',
      'unmuteMember groupId=$groupId userId=$userId',
    );
    await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/members/$userId/unmute',
      authenticated: true,
    );
  }

  Future<GroupsChatGroupModel> updatePermissions({
    required int groupId,
    String? messagePermission,
    String? editPermission,
    String? memberListPermission,
    String? reactionViewPermission,
    String? joinLinkPermission,
  }) async {
    GroupsChatLogger.log(
      'service',
      'updatePermissions groupId=$groupId message=$messagePermission edit=$editPermission members=$memberListPermission reactions=$reactionViewPermission link=$joinLinkPermission',
    );
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/permissions',
      authenticated: true,
      body: _permissionBody(
        messagePermission: messagePermission,
        editPermission: editPermission,
        memberListPermission: memberListPermission,
        reactionViewPermission: reactionViewPermission,
        joinLinkPermission: joinLinkPermission,
      ),
    );
    final data = response['data'];
    final group = data is Map ? data['group'] : null;
    if (group is Map) {
      return GroupsChatGroupModel.fromJson(Map<String, dynamic>.from(group));
    }
    throw const ApiException('Unable to update group permissions');
  }

  Future<GroupsChatGroupModel> regenerateJoinLink({
    required int groupId,
  }) async {
    GroupsChatLogger.log('service', 'regenerateJoinLink groupId=$groupId');
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/join-link/regenerate',
      authenticated: true,
    );
    final data = response['data'];
    final group = data is Map ? data['group'] : null;
    if (group is Map) {
      return GroupsChatGroupModel.fromJson(Map<String, dynamic>.from(group));
    }
    throw const ApiException('Unable to change join link');
  }

  Map<String, dynamic> _permissionBody({
    String? messagePermission,
    String? editPermission,
    String? memberListPermission,
    String? reactionViewPermission,
    String? joinLinkPermission,
  }) {
    final body = <String, dynamic>{};
    if (messagePermission != null) {
      body['message_permission'] = messagePermission;
    }
    if (editPermission != null) {
      body['edit_permission'] = editPermission;
    }
    if (memberListPermission != null) {
      body['member_list_permission'] = memberListPermission;
    }
    if (reactionViewPermission != null) {
      body['reaction_view_permission'] = reactionViewPermission;
    }
    if (joinLinkPermission != null) {
      body['join_link_permission'] = joinLinkPermission;
    }
    return body;
  }

  Future<GroupsChatPreferencesModel> muteNotifications({
    required int groupId,
  }) async {
    GroupsChatLogger.log('service', 'muteNotifications groupId=$groupId');
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/notifications/mute',
      authenticated: true,
      body: const <String, dynamic>{'duration': 'always'},
    );
    final data = response['data'];
    final preferences = data is Map ? data['preferences'] : null;
    if (preferences is Map) {
      return GroupsChatPreferencesModel.fromJson(
        Map<String, dynamic>.from(preferences),
      );
    }
    throw const ApiException('Unable to mute notifications');
  }

  Future<GroupsChatPreferencesModel> unmuteNotifications({
    required int groupId,
  }) async {
    GroupsChatLogger.log('service', 'unmuteNotifications groupId=$groupId');
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/notifications/unmute',
      authenticated: true,
    );
    final data = response['data'];
    final preferences = data is Map ? data['preferences'] : null;
    if (preferences is Map) {
      return GroupsChatPreferencesModel.fromJson(
        Map<String, dynamic>.from(preferences),
      );
    }
    throw const ApiException('Unable to unmute notifications');
  }

  Future<GroupsChatMessagesResponse> fetchMessages({
    required int groupId,
    int? offset,
    int? limit,
    int? beforeMessageId,
    int? afterMessageId,
    List<int>? messageIds,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (offset != null) {
      queryParameters['offset'] = offset;
    }
    if (limit != null) {
      queryParameters['limit'] = limit;
    }
    if (beforeMessageId != null) {
      queryParameters['before_message_id'] = beforeMessageId;
    }
    if (afterMessageId != null) {
      queryParameters['after_message_id'] = afterMessageId;
    }
    final normalizedMessageIds =
        messageIds
            ?.where((id) => id > 0)
            .toSet()
            .take(100)
            .toList(growable: false) ??
        const <int>[];
    if (normalizedMessageIds.isNotEmpty) {
      queryParameters['message_ids'] = normalizedMessageIds.join(',');
    }

    GroupsChatLogger.log(
      'service',
      'fetchMessages groupId=$groupId offset=${offset ?? '-'} limit=${limit ?? '-'} before=${beforeMessageId ?? '-'} after=${afterMessageId ?? '-'} ids=${normalizedMessageIds.length}',
    );
    final response = await _apiClient.get(
      '${ApiEndpoints.groupsChatGroups}/$groupId/messages',
      authenticated: true,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final result = GroupsChatMessagesResponse.fromJson(response);
    GroupsChatLogger.log(
      'service',
      'fetchMessages success groupId=$groupId count=${result.messages.length} hasMore=${result.hasMore}',
    );
    return result;
  }

  Future<void> deleteMessage({required int messageId}) async {
    GroupsChatLogger.log('service', 'deleteMessage messageId=$messageId');
    await _apiClient.delete(
      '/api-addon-messangr/groups-chat/messages/$messageId',
      authenticated: true,
    );
  }

  Future<void> reactToMessage({
    required int messageId,
    required String reaction,
    required bool shouldReact,
  }) async {
    GroupsChatLogger.log(
      'service',
      'reactToMessage messageId=$messageId reaction=$reaction shouldReact=$shouldReact',
    );
    await _apiClient.post(
      '/api-addon-messangr/groups-chat/messages/$messageId/reactions',
      authenticated: true,
      body: <String, dynamic>{
        'reaction': reaction,
        'do': shouldReact ? 'react' : 'unreact',
      },
    );
  }

  Future<GroupsChatReactionAuthorsResponse> fetchReactionAuthors({
    required int messageId,
    String reactionType = 'all',
    int? offset,
  }) async {
    GroupsChatLogger.log(
      'service',
      'fetchReactionAuthors messageId=$messageId reaction=$reactionType offset=${offset ?? 0}',
    );
    final queryParameters = <String, dynamic>{'reaction_type': reactionType};
    if (offset != null) {
      queryParameters['offset'] = offset;
    }
    final response = await _apiClient.get(
      '/api-addon-messangr/groups-chat/messages/$messageId/reactions',
      authenticated: true,
      queryParameters: queryParameters,
    );
    return GroupsChatReactionAuthorsResponse.fromJson(response);
  }

  Future<GroupsChatEventsResponse> fetchEvents({
    required int groupId,
    int? afterEventId,
    int? limit,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (afterEventId != null && afterEventId > 0) {
      queryParameters['after_event_id'] = afterEventId;
    }
    if (limit != null) {
      queryParameters['limit'] = limit;
    }

    final response = await _apiClient.get(
      '${ApiEndpoints.groupsChatGroups}/$groupId/events',
      authenticated: true,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return GroupsChatEventsResponse.fromJson(response);
  }

  Future<String> uploadPhoto({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final response = await _apiClient.postMultipart(
        ApiEndpoints.groupsChatUploadPhoto,
        authenticated: true,
        fileBytes: bytes,
        filename: filename,
      );
      return _extractUploadSource(
        response,
        nestedKey: 'photo',
        emptyMessage: 'Group photo upload returned empty source',
      );
    } on ApiException catch (error) {
      if (!_isMissingGroupsUploadApi(error)) {
        rethrow;
      }
      GroupsChatLogger.log(
        'service',
        'uploadPhoto groups endpoint missing; using legacy photo upload fallback',
      );
      final response = await _apiClient.postMultipart(
        ApiEndpoints.chatUploadPhoto,
        authenticated: true,
        fileBytes: bytes,
        filename: filename,
      );
      return _extractUploadSource(
        response,
        nestedKey: 'photo',
        emptyMessage: 'Photo upload returned empty source',
      );
    }
  }

  Future<String> uploadVideo({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final response = await _apiClient.postMultipart(
        ApiEndpoints.groupsChatUploadVideo,
        authenticated: true,
        fileBytes: bytes,
        filename: filename,
      );
      return _extractUploadSource(
        response,
        nestedKey: 'video',
        emptyMessage: 'Group video upload returned empty source',
      );
    } on ApiException catch (error) {
      if (!_isMissingGroupsUploadApi(error)) {
        rethrow;
      }
      GroupsChatLogger.log(
        'service',
        'uploadVideo groups endpoint missing; using legacy file upload fallback',
      );
      try {
        return await _uploadLegacyFileSource(
          bytes: bytes,
          filename: filename,
          emptyMessage: 'Video fallback upload returned empty source',
        );
      } on ApiException catch (fallbackError) {
        if (_isUnsupportedFileType(fallbackError)) {
          throw const ApiException(
            'Server file upload does not allow video files yet. Deploy api-addon-messangr/modules/chat/controller.php or the groups_chat upload routes.',
          );
        }
        rethrow;
      }
    }
  }

  Future<String> uploadVoiceNote({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final response = await _apiClient.postMultipart(
        ApiEndpoints.groupsChatUploadVoiceNote,
        authenticated: true,
        fileBytes: bytes,
        filename: filename,
      );
      return _extractUploadSource(
        response,
        nestedKey: 'voice_note',
        emptyMessage: 'Group voice note upload returned empty source',
      );
    } on ApiException catch (error) {
      if (!_isMissingGroupsUploadApi(error)) {
        rethrow;
      }
      GroupsChatLogger.log(
        'service',
        'uploadVoiceNote groups endpoint missing; using legacy file upload fallback',
      );
      try {
        return await _uploadLegacyFileSource(
          bytes: bytes,
          filename: filename,
          emptyMessage: 'Voice note fallback upload returned empty source',
        );
      } on ApiException catch (fallbackError) {
        if (_isUnsupportedFileType(fallbackError)) {
          throw const ApiException(
            'Server file upload does not allow voice note files yet. Deploy api-addon-messangr/modules/chat/controller.php or the groups_chat upload routes.',
          );
        }
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> uploadFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    Map<String, dynamic> payload;
    try {
      final response = await _apiClient.postMultipart(
        ApiEndpoints.groupsChatUploadFile,
        authenticated: true,
        fileBytes: bytes,
        filename: filename,
      );
      payload = _extractFileUploadPayload(response);
    } on ApiException catch (error) {
      if (!_isMissingGroupsUploadApi(error)) {
        rethrow;
      }
      GroupsChatLogger.log(
        'service',
        'uploadFile groups endpoint missing; using legacy file upload fallback',
      );
      final response = await _apiClient.postMultipart(
        ApiEndpoints.chatUploadFile,
        authenticated: true,
        fileBytes: bytes,
        filename: filename,
      );
      payload = _extractFileUploadPayload(response);
    }
    final source = payload['source']?.toString().trim() ?? '';
    if (source.isEmpty) {
      throw const ApiException('Group file upload returned empty source');
    }
    return payload;
  }

  Future<String> _uploadLegacyFileSource({
    required Uint8List bytes,
    required String filename,
    required String emptyMessage,
  }) async {
    final response = await _apiClient.postMultipart(
      ApiEndpoints.chatUploadFile,
      authenticated: true,
      fileBytes: bytes,
      filename: filename,
    );
    return _extractUploadSource(
      response,
      nestedKey: 'file',
      emptyMessage: emptyMessage,
    );
  }

  Map<String, dynamic> _extractFileUploadPayload(
    Map<String, dynamic> response,
  ) {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : <String, dynamic>{};
    final rawFile = data['file'] is Map
        ? Map<String, dynamic>.from(data['file'] as Map)
        : <String, dynamic>{};
    return <String, dynamic>{
      ...rawFile,
      if (data['source'] != null) 'source': data['source'],
      if (data['url'] != null) 'url': data['url'],
    };
  }

  String _extractUploadSource(
    Map<String, dynamic> response, {
    required String nestedKey,
    required String emptyMessage,
  }) {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : <String, dynamic>{};
    final nested = data[nestedKey] is Map
        ? Map<String, dynamic>.from(data[nestedKey] as Map)
        : <String, dynamic>{};
    final source =
        data['source']?.toString() ?? nested['source']?.toString() ?? '';
    if (source.trim().isEmpty) {
      throw ApiException(emptyMessage);
    }
    return source.trim();
  }

  bool _isMissingGroupsUploadApi(ApiException error) {
    final statusCode = error.statusCode ?? 0;
    final message = error.message.toLowerCase();
    if ((statusCode >= 300 && statusCode < 400) || statusCode == 404) {
      return true;
    }
    return message.contains('group media upload api is missing') ||
        message.contains('api route is missing');
  }

  bool _isUnsupportedFileType(ApiException error) {
    final message = error.message.toLowerCase();
    return message.contains('file type') &&
        (message.contains('not valid') || message.contains('not supported'));
  }

  Future<GroupsChatMessageModel> sendMessage({
    required int groupId,
    String? message,
    String? photo,
    String? video,
    String? voiceNote,
    Map<String, dynamic>? file,
  }) async {
    final trimmedMessage = message?.trim() ?? '';
    final trimmedPhoto = photo?.trim() ?? '';
    final trimmedVideo = video?.trim() ?? '';
    final trimmedVoiceNote = voiceNote?.trim() ?? '';
    final hasFile = file != null && file.isNotEmpty;
    final messageType = trimmedPhoto.isNotEmpty
        ? 'image'
        : trimmedVideo.isNotEmpty
        ? 'video'
        : trimmedVoiceNote.isNotEmpty
        ? 'audio'
        : hasFile
        ? 'file'
        : 'text';
    GroupsChatLogger.log(
      'service',
      'sendMessage groupId=$groupId type=$messageType length=${trimmedMessage.length}',
    );
    final response = await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/messages',
      authenticated: true,
      body: <String, dynamic>{
        if (trimmedMessage.isNotEmpty) 'message': trimmedMessage,
        'message_type': messageType,
        if (trimmedPhoto.isNotEmpty) 'photo': trimmedPhoto,
        if (trimmedVideo.isNotEmpty) 'video': trimmedVideo,
        if (trimmedVoiceNote.isNotEmpty) 'voice_note': trimmedVoiceNote,
        if (hasFile) 'file': file,
      },
    );
    final data = response['data'];
    final messagePayload = data is Map ? data['message'] : null;
    if (messagePayload is Map) {
      final sent = GroupsChatMessageModel.fromJson(
        Map<String, dynamic>.from(messagePayload),
      );
      GroupsChatLogger.log(
        'service',
        'sendMessage success groupId=$groupId messageId=${sent.messageId}',
      );
      return sent;
    }
    throw const ApiException('Unable to send message');
  }

  Future<void> markGroupRead({required int groupId, int? lastMessageId}) async {
    GroupsChatLogger.log(
      'service',
      'markGroupRead groupId=$groupId lastMessageId=${lastMessageId ?? '-'}',
    );
    await _apiClient.post(
      '${ApiEndpoints.groupsChatGroups}/$groupId/read',
      authenticated: true,
      body: <String, dynamic>{
        if (lastMessageId != null && lastMessageId > 0)
          'last_message_id': lastMessageId,
      },
    );
  }
}
