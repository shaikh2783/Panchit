import 'dart:convert';

class ChatCallConnectionModel {
  const ChatCallConnectionModel({
    required this.provider,
    required this.room,
    required this.token,
    required this.appId,
    required this.userId,
    required this.requiredClientFields,
    required this.config,
  });

  final String provider;
  final String room;
  final String token;
  final String appId;
  final int userId;
  final List<String> requiredClientFields;
  final Map<String, dynamic> config;

  ChatCallConnectionModel copyWithPlaybackUrl(String playbackUrl) {
    return ChatCallConnectionModel(
      provider: provider,
      room: room,
      token: token,
      appId: appId,
      userId: userId,
      requiredClientFields: requiredClientFields,
      config: <String, dynamic>{...config, 'playback_url': playbackUrl},
    );
  }

  bool get hasAgoraCredentials => appId.isNotEmpty && room.isNotEmpty;

  bool get isWebRtc => provider.trim().toLowerCase() == 'webrtc';

  String get publishUrl =>
      _decodeHtmlEntities(config['publish_url']?.toString().trim() ?? '');

  String get playbackUrl =>
      _decodeHtmlEntities(config['playback_url']?.toString().trim() ?? '');

  List<Map<String, dynamic>> get iceServers {
    final raw = config['ice_servers'];
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String get mediaTopology =>
      config['media_topology']?.toString().trim().toLowerCase() ?? '';

  bool get p2pEnabled => _parseBool(config['p2p_enabled']);

  String get p2pRole =>
      config['p2p_role']?.toString().trim().toLowerCase() ?? '';

  int get peerUserId => _parseInt(config['peer_user_id']);

  bool get canUseDirectP2p =>
      p2pEnabled &&
      mediaTopology == 'p2p' &&
      peerUserId > 0 &&
      <String>{'offerer', 'answerer'}.contains(p2pRole);

  List<ChatCallParticipantModel> get participants {
    final raw = config['participants'];
    if (raw is! List) {
      return const <ChatCallParticipantModel>[];
    }
    return raw
        .whereType<Map>()
        .map(
          (item) => ChatCallParticipantModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  List<ChatCallParticipantModel> get allParticipants {
    final raw = config['all_participants'];
    if (raw is! List) {
      return participants;
    }
    return raw
        .whereType<Map>()
        .map(
          (item) => ChatCallParticipantModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  bool get hasWebRtcConnection =>
      isWebRtc &&
      room.isNotEmpty &&
      publishUrl.isNotEmpty &&
      playbackUrl.isNotEmpty;

  factory ChatCallConnectionModel.fromJson(Map<String, dynamic> json) {
    final config = Map<String, dynamic>.from(
      (json['config'] as Map?) ?? const <String, dynamic>{},
    );
    final tokenConfig = _decodeConnectionToken(json['token']);
    final provider = json['provider']?.toString() ?? '';
    final isWebRtc = provider.trim().toLowerCase() == 'webrtc';
    if (isWebRtc && tokenConfig.isNotEmpty) {
      const fallbackKeys = <String>[
        'publish_url',
        'playback_url',
        'own_stream_id',
        'own_stream_key',
        'remote_stream_id',
        'remote_stream_key',
        'ice_servers',
        'realtime',
        'media_topology',
        'p2p_enabled',
        'p2p_role',
        'peer_user_id',
        'signaling',
        'sfu_fallback',
      ];
      for (final key in fallbackKeys) {
        final existing = config[key];
        final hasExisting = existing is List
            ? existing.isNotEmpty
            : existing is Map
            ? existing.isNotEmpty
            : existing?.toString().trim().isNotEmpty == true;
        if (!hasExisting && tokenConfig.containsKey(key)) {
          config[key] = tokenConfig[key];
        }
      }
    }
    final rawFields = (json['required_client_fields'] as List?) ?? const [];

    return ChatCallConnectionModel(
      provider: provider,
      room: json['room']?.toString().trim().isNotEmpty == true
          ? json['room'].toString()
          : tokenConfig['room']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      appId: config['app_id']?.toString() ?? '',
      userId: _parseInt(config['user_id']),
      requiredClientFields: rawFields
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
      config: config,
    );
  }

  static Map<String, dynamic> _decodeConnectionToken(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return const <String, dynamic>{};
    }

    final decodedText = _decodeHtmlEntities(raw);
    if (!decodedText.startsWith('{')) {
      return const <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(decodedText);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return const <String, dynamic>{};
  }

  static String _decodeHtmlEntities(String value) {
    var result = value;
    for (var index = 0; index < 2; index++) {
      result = result
          .replaceAll('&quot;', '"')
          .replaceAll('&#34;', '"')
          .replaceAll('&#x22;', '"')
          .replaceAll('&#039;', "'")
          .replaceAll('&#x27;', "'")
          .replaceAll('&apos;', "'")
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&amp;', '&');
    }
    return result.trim();
  }
}

class ChatCallModel {
  const ChatCallModel({
    required this.callId,
    required this.fromUserId,
    required this.toUserId,
    required this.room,
    required this.isVideoCall,
    required this.isAudioCall,
    required this.isMissedCall,
    required this.isIngoing,
    required this.answered,
    required this.declined,
    required this.time,
    required this.timeAgo,
    required this.updatedAt,
    required this.callerName,
    required this.callerPicture,
    required this.counterparty,
    required this.connection,
    required this.participants,
    required this.invite,
    required this.isGroupCall,
    required this.isGroupCallInvite,
    required this.participantCount,
    required this.pendingInviteCount,
  });

  final int callId;
  final int fromUserId;
  final int toUserId;
  final String room;
  final bool isVideoCall;
  final bool isAudioCall;
  final bool isMissedCall;
  final bool isIngoing;
  final bool answered;
  final bool declined;
  final String time;
  final String timeAgo;
  final String updatedAt;
  final String callerName;
  final String callerPicture;
  final ChatCallCounterpartyModel? counterparty;
  final ChatCallConnectionModel? connection;
  final List<ChatCallParticipantModel> participants;
  final ChatCallInviteModel? invite;
  final bool isGroupCall;
  final bool isGroupCallInvite;
  final int participantCount;
  final int pendingInviteCount;

  String get displayName {
    final counterpartyName = counterparty?.fullName.trim() ?? '';
    if (counterpartyName.isNotEmpty) {
      return counterpartyName;
    }
    return callerName.trim().isNotEmpty ? callerName : 'Unknown';
  }

  String get displayPicture => counterparty?.picture ?? callerPicture;

  static String normalizePictureUrl(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }

    final nestedUrl = RegExp(
      r'^https?://.+?/content/uploads/(https?://.+)$',
    ).firstMatch(raw);
    if (nestedUrl != null) {
      return nestedUrl.group(1)?.trim() ?? raw;
    }

    return raw;
  }

  factory ChatCallModel.fromJson(Map<String, dynamic> json) {
    final connectionJson = json['connection'];
    final counterpartyJson = json['counterparty'];
    final rawParticipants =
        (json['participants'] as List?) ??
        ((connectionJson is Map)
            ? ((connectionJson['config'] as Map?)?['all_participants'] as List?)
            : null) ??
        const [];
    final participants = rawParticipants
        .whereType<Map>()
        .map(
          (item) => ChatCallParticipantModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
    final inviteJson = json['invite'];

    return ChatCallModel(
      callId: _parseInt(json['call_id']),
      fromUserId: _parseInt(json['from_user_id']),
      toUserId: _parseInt(json['to_user_id']),
      room: json['room']?.toString() ?? '',
      isVideoCall: _parseBool(json['is_video_call'] ?? json['is_video']),
      isAudioCall: _parseBool(json['is_audio_call'] ?? json['is_audio']),
      isMissedCall: _parseBool(json['is_missed_call']),
      isIngoing: _parseBool(json['is_ingoing']),
      answered: _parseBool(json['answered']),
      declined: _parseBool(json['declined']),
      time: json['time']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      callerName: json['caller_name']?.toString() ?? '',
      callerPicture: normalizePictureUrl(json['caller_picture']),
      counterparty: counterpartyJson is Map
          ? ChatCallCounterpartyModel.fromJson(
              Map<String, dynamic>.from(counterpartyJson),
            )
          : null,
      connection: connectionJson is Map
          ? ChatCallConnectionModel.fromJson(
              Map<String, dynamic>.from(connectionJson),
            )
          : null,
      participants: participants,
      invite: inviteJson is Map
          ? ChatCallInviteModel.fromJson(Map<String, dynamic>.from(inviteJson))
          : null,
      isGroupCall: _parseBool(json['is_group_call']),
      isGroupCallInvite: _parseBool(json['is_group_call_invite']),
      participantCount: _parseInt(json['participant_count']),
      pendingInviteCount: _parseInt(json['pending_invite_count']),
    );
  }
}

class ChatCallParticipantModel {
  const ChatCallParticipantModel({
    required this.userId,
    required this.userName,
    required this.fullName,
    required this.picture,
    required this.isVerified,
    required this.isSubscribed,
    required this.role,
    required this.status,
    required this.isActive,
    required this.isCurrentUser,
    required this.streamId,
    required this.streamKey,
    required this.playbackUrl,
  });

  final int userId;
  final String userName;
  final String fullName;
  final String picture;
  final bool isVerified;
  final bool isSubscribed;
  final String role;
  final String status;
  final bool isActive;
  final bool isCurrentUser;
  final int streamId;
  final String streamKey;
  final String playbackUrl;

  String get displayName {
    final name = fullName.trim();
    return name.isNotEmpty ? name : userName.trim();
  }

  factory ChatCallParticipantModel.fromJson(Map<String, dynamic> json) {
    final connection =
        (json['connection'] as Map?) ?? const <String, dynamic>{};
    return ChatCallParticipantModel(
      userId: _parseInt(json['user_id'] ?? json['id']),
      userName: json['user_name']?.toString() ?? '',
      fullName:
          json['user_fullname']?.toString() ??
          [
            json['user_firstname']?.toString() ?? '',
            json['user_lastname']?.toString() ?? '',
          ].where((part) => part.trim().isNotEmpty).join(' ').trim(),
      picture: ChatCallModel.normalizePictureUrl(
        json['user_picture'] ?? json['picture'],
      ),
      isVerified: _parseBool(json['user_verified'] ?? json['is_verified']),
      isSubscribed: _parseBool(json['user_subscribed']),
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isActive: _parseBool(json['is_active']),
      isCurrentUser: _parseBool(json['is_current_user']),
      streamId: _parseInt(connection['stream_id'] ?? json['stream_id']),
      streamKey:
          connection['stream_key']?.toString() ??
          json['stream_key']?.toString() ??
          '',
      playbackUrl:
          connection['playback_url']?.toString() ??
          json['playback_url']?.toString() ??
          '',
    );
  }
}

class ChatCallInviteModel {
  const ChatCallInviteModel({
    required this.inviteId,
    required this.invitedByUserId,
    required this.invitedByName,
    required this.invitedByPicture,
    required this.status,
    required this.expiresAt,
  });

  final int inviteId;
  final int invitedByUserId;
  final String invitedByName;
  final String invitedByPicture;
  final String status;
  final String expiresAt;

  factory ChatCallInviteModel.fromJson(Map<String, dynamic> json) {
    return ChatCallInviteModel(
      inviteId: _parseInt(json['invite_id']),
      invitedByUserId: _parseInt(json['invited_by_user_id']),
      invitedByName: json['invited_by_name']?.toString() ?? '',
      invitedByPicture: ChatCallModel.normalizePictureUrl(
        json['invited_by_picture'],
      ),
      status: json['status']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString() ?? '',
    );
  }
}

class ChatCallCounterpartyModel {
  const ChatCallCounterpartyModel({
    required this.userId,
    required this.userName,
    required this.fullName,
    required this.picture,
    required this.isVerified,
    required this.isSubscribed,
  });

  final int userId;
  final String userName;
  final String fullName;
  final String picture;
  final bool isVerified;
  final bool isSubscribed;

  factory ChatCallCounterpartyModel.fromJson(Map<String, dynamic> json) {
    return ChatCallCounterpartyModel(
      userId: _parseInt(json['user_id']),
      userName: json['user_name']?.toString() ?? '',
      fullName:
          json['user_fullname']?.toString() ??
          [
            json['user_firstname']?.toString() ?? '',
            json['user_lastname']?.toString() ?? '',
          ].where((part) => part.trim().isNotEmpty).join(' '),
      picture: ChatCallModel.normalizePictureUrl(json['user_picture']),
      isVerified: _parseBool(json['user_verified']),
      isSubscribed: _parseBool(json['user_subscribed']),
    );
  }
}

class ChatCallsHistoryResponse {
  const ChatCallsHistoryResponse({
    required this.items,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<ChatCallModel> items;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  factory ChatCallsHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawItems = (data['items'] as List?) ?? const [];

    return ChatCallsHistoryResponse(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => ChatCallModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: data['next_offset'] == null
          ? null
          : _parseInt(data['next_offset']),
      hasMore: _parseBool(data['has_more']),
    );
  }
}

class ChatIncomingCallResult {
  const ChatIncomingCallResult({required this.hasNewCall, required this.call});

  final bool hasNewCall;
  final ChatCallModel? call;

  factory ChatIncomingCallResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final callJson = data['call'];

    return ChatIncomingCallResult(
      hasNewCall: _parseBool(data['has_new_call']),
      call: callJson is Map
          ? ChatCallModel.fromJson(Map<String, dynamic>.from(callJson))
          : null,
    );
  }
}

class ChatCallStartResult {
  const ChatCallStartResult({
    required this.status,
    required this.message,
    required this.call,
  });

  final String status;
  final String message;
  final ChatCallModel? call;

  factory ChatCallStartResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final callJson = data['call'];

    return ChatCallStartResult(
      status: data['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      call: callJson is Map
          ? ChatCallModel.fromJson(Map<String, dynamic>.from(callJson))
          : null,
    );
  }
}

class ChatCallResponseResult {
  const ChatCallResponseResult({
    required this.status,
    required this.message,
    required this.call,
    required this.event,
    required this.reason,
    required this.displayStatus,
  });

  final String status;
  final String message;
  final ChatCallModel? call;
  final String event;
  final String reason;
  final String displayStatus;

  factory ChatCallResponseResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final callJson = data['call'];

    return ChatCallResponseResult(
      status: data['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      call: callJson is Map
          ? ChatCallModel.fromJson(Map<String, dynamic>.from(callJson))
          : null,
      event: data['event']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
      displayStatus: data['display_status']?.toString() ?? '',
    );
  }
}

class ChatCallParticipantsResult {
  const ChatCallParticipantsResult({
    required this.callId,
    required this.participants,
    required this.activeCount,
    required this.pendingCount,
    required this.call,
  });

  final int callId;
  final List<ChatCallParticipantModel> participants;
  final int activeCount;
  final int pendingCount;
  final ChatCallModel? call;

  factory ChatCallParticipantsResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawParticipants = (data['participants'] as List?) ?? const [];
    final callJson = data['call'];
    return ChatCallParticipantsResult(
      callId: _parseInt(data['call_id']),
      participants: rawParticipants
          .whereType<Map>()
          .map(
            (item) => ChatCallParticipantModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      activeCount: _parseInt(data['active_count']),
      pendingCount: _parseInt(data['pending_count']),
      call: callJson is Map
          ? ChatCallModel.fromJson(Map<String, dynamic>.from(callJson))
          : null,
    );
  }
}

class ChatWebRtcSignalModel {
  const ChatWebRtcSignalModel({
    required this.signalId,
    required this.callId,
    required this.fromUserId,
    required this.toUserId,
    required this.generation,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final int signalId;
  final int callId;
  final int fromUserId;
  final int toUserId;
  final int generation;
  final String type;
  final Map<String, dynamic> payload;
  final String createdAt;

  factory ChatWebRtcSignalModel.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return ChatWebRtcSignalModel(
      signalId: _parseInt(json['signal_id']),
      callId: _parseInt(json['call_id']),
      fromUserId: _parseInt(json['from_user_id']),
      toUserId: _parseInt(json['to_user_id']),
      generation: _parseInt(json['generation']),
      type: json['type']?.toString().trim().toLowerCase() ?? '',
      payload: rawPayload is Map
          ? Map<String, dynamic>.from(rawPayload)
          : const <String, dynamic>{},
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class ChatWebRtcSignalsResult {
  const ChatWebRtcSignalsResult({
    required this.items,
    required this.nextAfterId,
  });

  final List<ChatWebRtcSignalModel> items;
  final int nextAfterId;

  factory ChatWebRtcSignalsResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?) ?? const <String, dynamic>{};
    final rawItems = (data['items'] as List?) ?? const [];
    final items = rawItems
        .whereType<Map>()
        .map(
          (item) =>
              ChatWebRtcSignalModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
    final explicitNext = _parseInt(data['next_after_id']);
    return ChatWebRtcSignalsResult(
      items: items,
      nextAfterId: explicitNext > 0
          ? explicitNext
          : items.fold<int>(
              0,
              (highest, item) =>
                  item.signalId > highest ? item.signalId : highest,
            ),
    );
  }
}

class ChatWebRtcIceConfigModel {
  const ChatWebRtcIceConfigModel({
    required this.iceServers,
    required this.iceTransportPolicy,
    required this.ttlSeconds,
    required this.p2pEnabled,
    required this.mediaTopology,
    required this.p2pRole,
    required this.peerUserId,
    required this.p2pCapabilityReported,
  });

  final List<Map<String, dynamic>> iceServers;
  final String iceTransportPolicy;
  final int ttlSeconds;
  final bool p2pEnabled;
  final String mediaTopology;
  final String p2pRole;
  final int peerUserId;
  final bool p2pCapabilityReported;

  factory ChatWebRtcIceConfigModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?) ?? const <String, dynamic>{};
    final rawServers = data['ice_servers'];
    return ChatWebRtcIceConfigModel(
      iceServers: rawServers is List
          ? rawServers
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList(growable: false)
          : const <Map<String, dynamic>>[],
      iceTransportPolicy:
          data['ice_transport_policy']?.toString().trim().toLowerCase() ??
          'all',
      ttlSeconds: _parseInt(data['ttl_seconds']),
      p2pEnabled: _parseBool(data['p2p_enabled']),
      mediaTopology:
          data['media_topology']?.toString().trim().toLowerCase() ?? '',
      p2pRole: data['p2p_role']?.toString().trim().toLowerCase() ?? '',
      peerUserId: _parseInt(data['peer_user_id']),
      p2pCapabilityReported: _parseBool(data['p2p_capability_reported']),
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
