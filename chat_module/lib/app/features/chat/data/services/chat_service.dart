import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/api/api_endpoints.dart';
import '../../../calls/data/models/chat_call_models.dart';
import '../models/chat_backgrounds_response.dart';
import '../models/chat_conversation_details.dart';
import '../models/chat_contacts_response.dart';
import '../models/chat_conversations_response.dart';
import '../models/chat_reaction_types_response.dart';
import '../models/chat_report_models.dart';
import '../models/chat_shared_content.dart';
import '../models/chat_stickers_response.dart';

const _stickerMessagePlaceholder = '\u200B';

class ChatService {
  ChatService(this._apiClient);

  final ChatModuleApiClient _apiClient;

  Future<ChatOpenResult> openConversation({
    int? userId,
    int? conversationId,
    bool createIfMissing = true,
    String? openToken,
  }) async {
    final trimmedOpenToken = openToken?.trim() ?? '';
    final response = await _apiClient.post(
      ApiEndpoints.chatOpen,
      authenticated: true,
      body: <String, dynamic>{
        if (trimmedOpenToken.isNotEmpty) ...<String, dynamic>{
          'open_token': trimmedOpenToken,
        } else ...<String, dynamic>{
          ...?conversationId.mapToQuery('conversation_id'),
          ...?userId.mapToQuery('user_id'),
        },
        'create_if_missing': createIfMissing,
      },
    );
    return ChatOpenResult.fromJson(response);
  }

  Future<ChatConversationsResponse> fetchConversations({
    int? offset,
    String? query,
  }) async {
    final trimmedQuery = query?.trim() ?? '';
    final response = await _apiClient.get(
      ApiEndpoints.chatConversations,
      authenticated: true,
      queryParameters: <String, dynamic>{
        ...?offset.mapToQuery('offset'),
        if (trimmedQuery.isNotEmpty) 'query': trimmedQuery,
      },
    );
    return ChatConversationsResponse.fromJson(response);
  }

  Future<Map<String, dynamic>> fetchManifest() async {
    return _apiClient.get(ApiEndpoints.chatManifest, authenticated: true);
  }

  Future<ChatContactsResponse> fetchContacts() async {
    final response = await _apiClient.get(
      ApiEndpoints.chatContacts,
      authenticated: true,
    );
    return ChatContactsResponse.fromJson(response);
  }

  Future<ChatReactionTypesResponse> fetchReactionTypes() async {
    final response = await _apiClient.get(
      ApiEndpoints.chatReactionTypes,
      authenticated: true,
    );
    return ChatReactionTypesResponse.fromJson(response);
  }

  Future<ChatReportCategoriesResponse> fetchUserReportCategories() async {
    final response = await _apiClient.get(
      ApiEndpoints.userReportCategories,
      authenticated: true,
    );
    return ChatReportCategoriesResponse.fromJson(response);
  }

  Future<String> reportUser({
    required int userId,
    required int categoryId,
    String? reason,
  }) async {
    final trimmedReason = reason?.trim() ?? '';
    final response = await _apiClient.post(
      ApiEndpoints.userReport,
      authenticated: true,
      body: <String, dynamic>{
        'user_id': userId,
        'target_user_id': userId,
        'id': userId,
        'category': categoryId,
        if (trimmedReason.isNotEmpty) 'reason': trimmedReason,
      },
    );
    final message = response['message']?.toString().trim() ?? '';
    return message.isEmpty ? 'Your report has been submitted' : message;
  }

  Future<ChatCallsHistoryResponse> fetchCalls({int? offset}) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatCalls,
      authenticated: true,
      queryParameters: <String, dynamic>{...?offset.mapToQuery('offset')},
    );
    return ChatCallsHistoryResponse.fromJson(response);
  }

  Future<ChatSharedContentResponse> fetchSharedContent({
    required int conversationId,
    int? offset,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatShared,
      authenticated: true,
      queryParameters: <String, dynamic>{
        'conversation_id': conversationId,
        ...?offset.mapToQuery('offset'),
      },
    );
    return ChatSharedContentResponse.fromJson(response);
  }

  Future<ChatBackgroundsResponse> fetchChatBackgrounds() async {
    final response = await _apiClient.get(
      ApiEndpoints.chatBackgrounds,
      authenticated: true,
    );
    return ChatBackgroundsResponse.fromJson(response);
  }

  Future<ChatStickersResponse> fetchStickers({String? packName}) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatStickers,
      authenticated: true,
      queryParameters: <String, dynamic>{
        if (packName?.trim().isNotEmpty ?? false) 'pack_name': packName!.trim(),
      },
    );
    return ChatStickersResponse.fromJson(response);
  }

  Future<ChatStickerPacksResponse> fetchStickerPacks() async {
    final response = await _apiClient.get(
      ApiEndpoints.chatStickerPacks,
      authenticated: true,
    );
    return ChatStickerPacksResponse.fromJson(response);
  }

  Future<ChatConversationBackgroundResponse> fetchConversationBackground({
    required int conversationId,
  }) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.chatConversation}/$conversationId/background',
      authenticated: true,
    );
    return ChatConversationBackgroundResponse.fromJson(response);
  }

  Future<ChatBackgroundSaveResponse> saveConversationBackground({
    required int conversationId,
    int? backgroundId,
    String? type,
    String? value,
    String? preview,
    bool reset = false,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.chatConversation}/$conversationId/background',
      authenticated: true,
      body: <String, dynamic>{
        ...?backgroundId.mapToQuery('background_id'),
        if (type?.trim().isNotEmpty ?? false) 'type': type!.trim(),
        if (value?.trim().isNotEmpty ?? false) 'value': value!.trim(),
        if (preview?.trim().isNotEmpty ?? false) 'preview': preview!.trim(),
        if (reset) 'reset': true,
      },
    );
    return ChatBackgroundSaveResponse.fromJson(response);
  }

  Future<ChatConversationDetailsModel> fetchConversation({
    int? conversationId,
    int? userId,
    int? groupId,
    String? openToken,
  }) async {
    final trimmedOpenToken = openToken?.trim() ?? '';
    Future<Map<String, dynamic>> requestConversation({
      int? requestedConversationId,
      int? requestedUserId,
    }) {
      return _apiClient.get(
        ApiEndpoints.chatConversation,
        authenticated: true,
        queryParameters: trimmedOpenToken.isNotEmpty
            ? <String, dynamic>{'open_token': trimmedOpenToken}
            : <String, dynamic>{
                ...?requestedConversationId.mapToQuery('conversation_id'),
                ...?requestedUserId.mapToQuery('user_id'),
              },
      );
    }

    Future<ChatConversationDetailsModel?> tryResolveConversation({
      int? requestedConversationId,
      int? requestedUserId,
    }) async {
      final response = await requestConversation(
        requestedConversationId: requestedConversationId,
        requestedUserId: requestedUserId,
      );
      if (!_hasConversationPayload(response)) {
        return null;
      }
      return ChatConversationDetailsModel.fromJson(response);
    }

    var resolvedConversationId = conversationId;
    if (trimmedOpenToken.isEmpty &&
        resolvedConversationId == null &&
        (groupId ?? 0) > 0) {
      resolvedConversationId = await _resolveGroupConversationId(groupId!);
    }

    final initialResult = await tryResolveConversation(
      requestedConversationId: resolvedConversationId,
      requestedUserId: userId,
    );
    if (initialResult != null) {
      return initialResult;
    }

    final retryResult = await tryResolveConversation(
      requestedConversationId: resolvedConversationId,
      requestedUserId: userId,
    );
    if (retryResult != null) {
      return retryResult;
    }

    if (trimmedOpenToken.isEmpty && conversationId == null && userId != null) {
      final opened = await openConversation(
        userId: userId,
        createIfMissing: false,
      );
      if (opened.resolvedConversationId != 0) {
        final resolvedResult = await tryResolveConversation(
          requestedConversationId: opened.resolvedConversationId,
        );
        if (resolvedResult != null) {
          return resolvedResult;
        }
      }
    }

    throw const ApiException('Conversation response was empty');
  }

  Future<int?> _resolveGroupConversationId(int groupId) async {
    var offset = 0;
    final visitedOffsets = <int>{};

    while (visitedOffsets.add(offset)) {
      final response = await fetchConversations(offset: offset);
      for (final conversation in response.conversations) {
        if (conversation.nodeType == 'group' &&
            conversation.nodeId == groupId) {
          final conversationId = int.tryParse(conversation.id) ?? 0;
          if (conversationId > 0) {
            return conversationId;
          }
        }
      }

      final nextOffset = response.nextOffset;
      if (!response.hasMore || nextOffset == null || nextOffset == offset) {
        break;
      }
      offset = nextOffset;
    }

    return null;
  }

  Future<void> deleteConversation({required int conversationId}) async {
    await _apiClient.delete(
      '${ApiEndpoints.chatConversation}/$conversationId',
      authenticated: true,
    );
  }

  Future<void> deleteMessage({required int messageId}) async {
    await _apiClient.delete(
      '${ApiEndpoints.chatMessage}/$messageId',
      authenticated: true,
    );
  }

  Future<ChatMessageModel> editMessage({
    required int messageId,
    required String message,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.chatMessage}/$messageId/edit',
      authenticated: true,
      body: <String, dynamic>{'message': message.trim()},
    );
    final data = (response['data'] as Map<String, dynamic>?) ?? const {};
    final messageJson = (data['message'] as Map<String, dynamic>?) ?? const {};
    return ChatMessageModel.fromJson(messageJson);
  }

  Future<ChatMessageChangesResponse> fetchMessageChanges({
    required int conversationId,
    int? afterEventId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatMessagesChanges,
      authenticated: true,
      queryParameters: <String, dynamic>{
        'conversation_id': conversationId,
        ...?afterEventId.mapToQuery('after_event_id'),
      },
    );
    return ChatMessageChangesResponse.fromJson(response);
  }

  Future<ChatConversationStatusResponse> fetchConversationStatus({
    required int conversationId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatConversationStatus,
      authenticated: true,
      queryParameters: <String, dynamic>{'conversation_id': conversationId},
    );
    return ChatConversationStatusResponse.fromJson(response);
  }

  Future<void> markConversationSeen({
    List<int>? ids,
    List<int>? conversationIds,
  }) async {
    final normalizedIds =
        (ids ?? const <int>[]).where((item) => item > 0).toSet().toList()
          ..sort();
    final normalizedConversationIds =
        (conversationIds ?? const <int>[])
            .where((item) => item > 0)
            .toSet()
            .toList()
          ..sort();

    if (normalizedIds.isEmpty && normalizedConversationIds.isEmpty) {
      return;
    }

    await _apiClient.post(
      ApiEndpoints.chatActionsSeen,
      authenticated: true,
      body: <String, dynamic>{
        if (normalizedIds.isNotEmpty) 'ids': normalizedIds,
        if (normalizedConversationIds.isNotEmpty)
          'conversation_ids': normalizedConversationIds,
      },
    );
  }

  Future<ChatConversationPreferences> pinConversation({
    required int conversationId,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.chatConversation}/$conversationId/pin',
      authenticated: true,
    );
    return ChatConversationPreferences.fromJson(response);
  }

  Future<ChatConversationPreferences> unpinConversation({
    required int conversationId,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.chatConversation}/$conversationId/unpin',
      authenticated: true,
    );
    return ChatConversationPreferences.fromJson(response);
  }

  Future<ChatConversationPreferences> muteConversation({
    int? conversationId,
    int? targetUserId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatNotificationsMute,
      authenticated: true,
      body: <String, dynamic>{
        ...?conversationId.mapToQuery('conversation_id'),
        ...?targetUserId.mapToQuery('target_user_id'),
      },
    );
    return ChatConversationPreferences.fromJson(response);
  }

  Future<ChatConversationPreferences> unmuteConversation({
    int? conversationId,
    int? targetUserId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatNotificationsUnmute,
      authenticated: true,
      body: <String, dynamic>{
        ...?conversationId.mapToQuery('conversation_id'),
        ...?targetUserId.mapToQuery('target_user_id'),
      },
    );
    return ChatConversationPreferences.fromJson(response);
  }

  Future<ChatMessagesResponse> fetchMessages({
    required int conversationId,
    int? offset,
    int? lastMessageId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatMessages,
      authenticated: true,
      queryParameters: <String, dynamic>{
        'conversation_id': conversationId,
        ...?offset.mapToQuery('offset'),
        ...?lastMessageId.mapToQuery('last_message_id'),
      },
    );
    return ChatMessagesResponse.fromJson(response);
  }

  Future<ChatSendMessageResult> sendMessage({
    int? conversationId,
    String? message,
    String? photo,
    String? video,
    String? voiceNote,
    Map<String, dynamic>? file,
    Map<String, dynamic>? location,
    Map<String, dynamic>? contact,
    double? latitude,
    double? longitude,
    String? locationName,
    String? locationAddress,
    String? phoneNumber,
    String? contactName,
    int? stickerId,
    String? sticker,
    String? messageType,
    int? postId,
    int? reelId,
    int? productPostId,
    int? replyToMessageId,
    List<int>? recipients,
  }) async {
    final trimmedMessage = message?.trim() ?? '';
    final trimmedSticker = sticker?.trim() ?? '';
    final trimmedMessageType = messageType?.trim() ?? '';
    final trimmedLocationName = locationName?.trim() ?? '';
    final trimmedLocationAddress = locationAddress?.trim() ?? '';
    final trimmedPhoneNumber = phoneNumber?.trim() ?? '';
    final trimmedContactName = contactName?.trim() ?? '';
    final normalizedLocation = location == null
        ? null
        : Map<String, dynamic>.from(location);
    final normalizedContact = contact == null
        ? null
        : Map<String, dynamic>.from(contact);
    final hasLocationPayload =
        normalizedLocation != null || (latitude != null && longitude != null);
    final hasContactPayload =
        normalizedContact != null || trimmedPhoneNumber.isNotEmpty;
    final hasStickerPayload = stickerId != null || trimmedSticker.isNotEmpty;
    final resolvedMessage = trimmedMessage.isNotEmpty
        ? trimmedMessage
        : hasStickerPayload &&
              (photo ?? '').trim().isEmpty &&
              (video ?? '').trim().isEmpty &&
              (voiceNote ?? '').trim().isEmpty &&
              !hasLocationPayload &&
              !hasContactPayload
        ? _stickerMessagePlaceholder
        : '';
    final body = <String, dynamic>{
      if (resolvedMessage.isNotEmpty) 'message': resolvedMessage,
      if ((photo ?? '').trim().isNotEmpty) 'photo': photo!.trim(),
      if ((video ?? '').trim().isNotEmpty) 'video': video!.trim(),
      if ((voiceNote ?? '').trim().isNotEmpty) 'voice_note': voiceNote!.trim(),
      ...?file == null ? null : <String, dynamic>{'file': file},
      ...?normalizedLocation == null
          ? null
          : <String, dynamic>{'location': normalizedLocation},
      ...?normalizedContact == null
          ? null
          : <String, dynamic>{'contact': normalizedContact},
      if (normalizedLocation == null && latitude != null) 'latitude': latitude,
      if (normalizedLocation == null && longitude != null)
        'longitude': longitude,
      if (normalizedLocation == null && trimmedLocationName.isNotEmpty)
        'location_name': trimmedLocationName,
      if (normalizedLocation == null && trimmedLocationAddress.isNotEmpty)
        'location_address': trimmedLocationAddress,
      if (normalizedContact == null && trimmedPhoneNumber.isNotEmpty)
        'phone_number': trimmedPhoneNumber,
      if (normalizedContact == null && trimmedContactName.isNotEmpty)
        'contact_name': trimmedContactName,
      ...?stickerId.mapToQuery('sticker_id'),
      if (trimmedSticker.isNotEmpty) 'sticker': trimmedSticker,
      if (trimmedMessageType.isNotEmpty) 'message_type': trimmedMessageType,
      ...?postId.mapToQuery('post_id'),
      ...?reelId.mapToQuery('reel_id'),
      ...?productPostId.mapToQuery('product_post_id'),
      ...?replyToMessageId.mapToQuery('reply_to_message_id'),
      ...?conversationId.mapToQuery('conversation_id'),
      ...?recipients.nonEmptyMapToQuery('recipients'),
    };

    if (body.isEmpty ||
        (trimmedMessage.isEmpty &&
            (photo ?? '').trim().isEmpty &&
            (video ?? '').trim().isEmpty &&
            (voiceNote ?? '').trim().isEmpty &&
            file == null &&
            !hasLocationPayload &&
            !hasContactPayload &&
            stickerId == null &&
            (sticker ?? '').trim().isEmpty &&
            trimmedMessageType.isEmpty &&
            postId == null &&
            reelId == null &&
            productPostId == null)) {
      throw const ApiException('Message payload is empty');
    }

    if ((voiceNote ?? '').trim().isNotEmpty) {
      _logVoiceTrace('send message body', body);
    }

    final response = await _apiClient.post(
      ApiEndpoints.chatMessage,
      authenticated: true,
      body: body,
    );
    if ((voiceNote ?? '').trim().isNotEmpty) {
      _logVoiceTrace('send message response', response);
    }
    return ChatSendMessageResult.fromJson(response);
  }

  Future<ChatSendMessageResult> forwardMessage({
    required int sourceMessageId,
    int? conversationId,
    List<int>? recipients,
  }) {
    final body = <String, dynamic>{
      'source_message_id': sourceMessageId,
      ...?conversationId.mapToQuery('conversation_id'),
      ...?recipients.nonEmptyMapToQuery('recipients'),
    };

    return _apiClient
        .post(ApiEndpoints.chatMessageForward, authenticated: true, body: body)
        .then(ChatSendMessageResult.fromJson);
  }

  Future<void> reactToMessage({
    required int messageId,
    required String reaction,
    required bool shouldReact,
  }) async {
    await _apiClient.post(
      ApiEndpoints.chatReactionReact,
      authenticated: true,
      body: <String, dynamic>{
        'message_id': messageId,
        'reaction': reaction,
        'do': shouldReact ? 'react' : 'unreact',
      },
    );
  }

  Future<ChatCallStartResult> startCall({
    required int toUserId,
    required bool isVideoCall,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatCallStart,
      authenticated: true,
      body: <String, dynamic>{
        'type': isVideoCall ? 'video' : 'audio',
        'to_user_id': toUserId,
      },
    );
    return ChatCallStartResult.fromJson(response);
  }

  Future<ChatCallResponseResult> inviteWebRtcCallParticipant({
    required int callId,
    required int userId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatCallInvite,
      authenticated: true,
      body: <String, dynamic>{'call_id': callId, 'user_id': userId},
    );
    return ChatCallResponseResult.fromJson(response);
  }

  Future<ChatCallParticipantsResult> fetchWebRtcCallParticipants({
    required int callId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatCallParticipants,
      authenticated: true,
      queryParameters: <String, dynamic>{'call_id': callId},
    );
    return ChatCallParticipantsResult.fromJson(response);
  }

  Future<ChatCallResponseResult> leaveWebRtcCall({required int callId}) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatCallLeave,
      authenticated: true,
      body: <String, dynamic>{'call_id': callId},
    );
    return ChatCallResponseResult.fromJson(response);
  }

  Future<void> sendWebRtcCallSignal({
    required int callId,
    required int toUserId,
    required String clientSignalId,
    required int generation,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await _apiClient.post(
      ApiEndpoints.chatCallSignals,
      authenticated: true,
      body: <String, dynamic>{
        'call_id': callId,
        'to_user_id': toUserId,
        'client_signal_id': clientSignalId,
        'generation': generation,
        'type': type,
        'payload': payload,
      },
    );
  }

  Future<ChatWebRtcSignalsResult> fetchWebRtcCallSignals({
    required int callId,
    required int afterId,
    int limit = 100,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatCallSignals,
      authenticated: true,
      queryParameters: <String, dynamic>{
        'call_id': callId,
        'after_id': afterId,
        'limit': limit,
      },
    );
    return ChatWebRtcSignalsResult.fromJson(response);
  }

  Future<void> acknowledgeWebRtcCallSignals({
    required int callId,
    required int throughSignalId,
  }) async {
    if (throughSignalId <= 0) return;
    await _apiClient.post(
      ApiEndpoints.chatCallSignalsAck,
      authenticated: true,
      body: <String, dynamic>{
        'call_id': callId,
        'through_signal_id': throughSignalId,
      },
    );
  }

  Future<ChatWebRtcIceConfigModel> fetchWebRtcIceConfig({
    required int callId,
    bool? p2pCapability = true,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatCallIceConfig,
      authenticated: true,
      queryParameters: <String, dynamic>{
        'call_id': callId,
        if (p2pCapability != null) 'p2p_capable': p2pCapability ? 1 : 0,
      },
    );
    return ChatWebRtcIceConfigModel.fromJson(response);
  }

  Future<ChatCallResponseResult> checkCallResponse({
    required int callId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatCallCheckResponse,
      authenticated: true,
      queryParameters: <String, dynamic>{'call_id': callId},
    );
    return ChatCallResponseResult.fromJson(response);
  }

  Future<ChatIncomingCallResult> checkNewCall() async {
    final response = await _apiClient.get(
      ApiEndpoints.chatCallCheckNew,
      authenticated: true,
    );
    return ChatIncomingCallResult.fromJson(response);
  }

  Future<ChatCallResponseResult> answerCall({required int callId}) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatCallAnswer,
      authenticated: true,
      body: <String, dynamic>{'call_id': callId},
    );
    return ChatCallResponseResult.fromJson(response);
  }

  Future<ChatCallResponseResult> declineCall({
    required int callId,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatCallDecline,
      authenticated: true,
      body: <String, dynamic>{
        'call_id': callId,
        if (reason?.trim().isNotEmpty ?? false) 'reason': reason!.trim(),
      },
    );
    return ChatCallResponseResult.fromJson(response);
  }

  Future<ChatCallResponseResult> cancelCall({required int callId}) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatCallCancel,
      authenticated: true,
      body: <String, dynamic>{'call_id': callId},
    );
    return ChatCallResponseResult.fromJson(response);
  }

  Future<ChatCallResponseResult> endCall({required int callId}) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatCallEnd,
      authenticated: true,
      body: <String, dynamic>{'call_id': callId},
    );
    return ChatCallResponseResult.fromJson(response);
  }

  Future<void> updateCall({required int callId}) async {
    await _apiClient.post(
      ApiEndpoints.chatCallUpdate,
      authenticated: true,
      body: <String, dynamic>{'call_id': callId},
    );
  }

  Future<String> uploadPhoto({
    required Uint8List bytes,
    required String filename,
  }) async {
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

  Future<String> uploadVideo({
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await _apiClient.postMultipart(
      ApiEndpoints.chatUploadVideo,
      authenticated: true,
      fileBytes: bytes,
      filename: filename,
    );
    return _extractUploadSource(
      response,
      nestedKey: 'video',
      emptyMessage: 'Video upload returned empty source',
    );
  }

  Future<String> uploadVoiceNote({
    required Uint8List bytes,
    required String filename,
  }) async {
    _logVoiceTrace('upload voice note request', <String, dynamic>{
      'filename': filename,
      'bytes': bytes.length,
      'endpoint': ApiEndpoints.chatUploadVoiceNote,
    });
    final response = await _apiClient.postMultipart(
      ApiEndpoints.chatUploadVoiceNote,
      authenticated: true,
      fileBytes: bytes,
      filename: filename,
    );
    _logVoiceTrace('upload voice note response', response);
    final source = _extractUploadSource(
      response,
      nestedKey: 'voice_note',
      emptyMessage: 'Voice note upload returned empty source',
    );
    _logVoiceTrace('upload voice note extracted source', source);
    return source;
  }

  Future<ChatFileAttachmentModel> uploadFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await _apiClient.postMultipart(
      ApiEndpoints.chatUploadFile,
      authenticated: true,
      fileBytes: bytes,
      filename: filename,
    );
    final data = (response['data'] as Map<String, dynamic>?) ?? const {};
    final rawFile = (data['file'] as Map<String, dynamic>?) ?? const {};
    final payload = <String, dynamic>{
      ...rawFile,
      if (data['source'] != null) 'source': data['source'],
      if (data['url'] != null) 'url': data['url'],
    };
    final attachment = ChatFileAttachmentModel.fromJson(payload);
    if (!attachment.isMeaningful || attachment.source.trim().isEmpty) {
      throw const ApiException('File upload returned empty source');
    }
    return attachment;
  }

  String _extractUploadSource(
    Map<String, dynamic> response, {
    required String nestedKey,
    required String emptyMessage,
  }) {
    final data = (response['data'] as Map<String, dynamic>?) ?? const {};
    final source =
        data['source']?.toString() ??
        (data[nestedKey] as Map<String, dynamic>?)?['source']?.toString() ??
        '';
    if (source.trim().isEmpty) {
      throw ApiException(emptyMessage);
    }
    return source;
  }
}

void _logVoiceTrace(String label, Object? value) {
  debugPrint('[ChatVoiceTrace] $label: ${_prettyVoiceTraceValue(value)}');
}

String _prettyVoiceTraceValue(Object? value) {
  if (value == null) {
    return 'null';
  }
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}

class ChatOpenResult {
  const ChatOpenResult({
    required this.requestedUserId,
    required this.resolvedConversationId,
    required this.created,
    required this.openToken,
  });

  final int requestedUserId;
  final int resolvedConversationId;
  final bool created;
  final String openToken;

  factory ChatOpenResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    return ChatOpenResult(
      requestedUserId: _parseInt(data['requested_user_id']),
      resolvedConversationId: _parseInt(data['resolved_conversation_id']),
      created: _parseBool(data['created']),
      openToken: data['open_token']?.toString().trim() ?? '',
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

bool _hasConversationPayload(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is! Map<String, dynamic>) {
    return false;
  }

  final conversation = data['conversation'];
  if (conversation is Map<String, dynamic>) {
    final conversationId = _parseInt(
      conversation['conversation_id'] ?? data['resolved_conversation_id'],
    );
    return conversationId != 0;
  }

  final directConversationId = _parseInt(
    data['conversation_id'] ?? data['resolved_conversation_id'],
  );
  return directConversationId != 0;
}

extension on int? {
  Map<String, dynamic>? mapToQuery(String key) {
    final value = this;
    if (value == null) {
      return null;
    }
    return <String, dynamic>{key: value};
  }
}

extension on List<int>? {
  Map<String, dynamic>? nonEmptyMapToQuery(String key) {
    final value = this;
    if (value == null || value.isEmpty) {
      return null;
    }
    return <String, dynamic>{key: value};
  }
}
