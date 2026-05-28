class CallModel {
  final int callId;
  final String callType; // 'audio' or 'video'
  final String callStatus; // 'pending', 'active', 'ended', 'declined', 'cancelled'
  final bool answered;
  final bool declined;
  final int toUserId;
  final int fromUserId;
  final String fromUserName;
  final String? fromUserPicture;
  final String room;
  final DateTime createdTime;
  final String provider; // 'agora'
  final AgoraProviderData? providerData;
  final int? callDuration; // seconds
  final int? endedBy;

  CallModel({
    required this.callId,
    required this.callType,
    required this.callStatus,
    required this.answered,
    required this.declined,
    required this.toUserId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPicture,
    required this.room,
    required this.createdTime,
    required this.provider,
    this.providerData,
    this.callDuration,
    this.endedBy,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    // Parse answered and declined properly (can be String "1", int 1, or bool true)
    final answered = _parseBool(json['answered']);
    final declined = _parseBool(json['declined']);
    final isMissedCall = _parseBool(json['is_missed_call']);
    
    // Calculate call_status from the flags if not provided
    String callStatus;
    if (json['call_status'] != null && json['call_status'].toString().isNotEmpty) {
      callStatus = json['call_status'];
    } else {
      // Derive status from flags
      // If answered and has ended_by, it means the call ended
      // If answered but no ended_by, it means the call is active
      if (answered) {
        final hasEndedBy = json['ended_by'] != null && _parseInt(json['ended_by']) != null;
        callStatus = hasEndedBy ? 'ended' : 'active';
      } else if (declined || isMissedCall) {
        callStatus = 'declined'; // Call was declined or missed
      } else {
        callStatus = 'pending'; // Still waiting for answer
      }
    }
    
    // Parse call_type from is_video_call or call_type field
    String callType;
    if (json['call_type'] != null) {
      callType = json['call_type'];
    } else if (json['is_video_call'] != null) {
      final isVideo = _parseBool(json['is_video_call']);
      callType = isVideo ? 'video' : 'audio';
    } else {
      callType = 'audio';
    }
    
    // Extract from_user_name from caller_receiver if not provided directly
    String fromUserName = json['from_user_name'] ?? '';
    String? fromUserPicture = json['from_user_picture'];
    
    if (fromUserName.isEmpty && json['caller_receiver'] != null) {
      final callerReceiver = json['caller_receiver'];
      fromUserName = callerReceiver['user_fullname'] ?? 
                     '${callerReceiver['user_firstname'] ?? ''} ${callerReceiver['user_lastname'] ?? ''}'.trim();
      fromUserPicture = callerReceiver['user_picture'];
    }
    
    // Build provider_data from tokens if not provided as structured object
    AgoraProviderData? providerData;
    if (json['provider_data'] != null) {
      providerData = AgoraProviderData.fromJson(json['provider_data']);
    } else if (json['from_user_token'] != null || json['to_user_token'] != null) {
      // Build from individual token fields
      final fromUserId = _parseInt(json['from_user_id']) ?? 0;
      final toUserId = _parseInt(json['to_user_id']) ?? 0;
      final room = json['room'] ?? '';
      
      // Determine which token to use based on current user
      // For incoming calls, use to_user_token (receiver's token)
      final token = json['to_user_token'] ?? json['from_user_token'] ?? '';
      
      providerData = AgoraProviderData(
        appId: '06e8cc01e5ce4a1ba6d1254c2a5aa7da', // Default Agora App ID
        channelName: room,
        token: token,
        uid: toUserId, // Use receiver's ID as UID
      );
    }
    
    return CallModel(
      callId: _parseInt(json['call_id']) ?? 0,
      callType: callType,
      callStatus: callStatus,
      answered: answered,
      declined: declined,
      toUserId: _parseInt(json['to_user_id']) ?? 0,
      fromUserId: _parseInt(json['from_user_id']) ?? 0,
      fromUserName: fromUserName,
      fromUserPicture: fromUserPicture,
      room: json['room'] ?? '',
      createdTime: _parseDateTime(json['created_time']),
      provider: json['provider'] ?? 'agora',
      providerData: providerData,
      callDuration: _parseInt(json['call_duration']),
      endedBy: _parseInt(json['ended_by']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'call_type': callType,
      'call_status': callStatus,
      'answered': answered,
      'declined': declined,
      'to_user_id': toUserId,
      'from_user_id': fromUserId,
      'from_user_name': fromUserName,
      'from_user_picture': fromUserPicture,
      'room': room,
      'created_time': createdTime.toIso8601String(),
      'provider': provider,
      'provider_data': providerData?.toJson(),
      'call_duration': callDuration,
      'ended_by': endedBy,
    };
  }

  CallModel copyWith({
    int? callId,
    String? callType,
    String? callStatus,
    bool? answered,
    bool? declined,
    int? toUserId,
    int? fromUserId,
    String? fromUserName,
    String? fromUserPicture,
    String? room,
    DateTime? createdTime,
    String? provider,
    AgoraProviderData? providerData,
    int? callDuration,
    int? endedBy,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callType: callType ?? this.callType,
      callStatus: callStatus ?? this.callStatus,
      answered: answered ?? this.answered,
      declined: declined ?? this.declined,
      toUserId: toUserId ?? this.toUserId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserPicture: fromUserPicture ?? this.fromUserPicture,
      room: room ?? this.room,
      createdTime: createdTime ?? this.createdTime,
      provider: provider ?? this.provider,
      providerData: providerData ?? this.providerData,
      callDuration: callDuration ?? this.callDuration,
      endedBy: endedBy ?? this.endedBy,
    );
  }
}

class AgoraProviderData {
  final String appId;
  final String channelName;
  final String token;
  final int uid;

  AgoraProviderData({
    required this.appId,
    required this.channelName,
    required this.token,
    required this.uid,
  });

  factory AgoraProviderData.fromJson(Map<String, dynamic> json) {
    return AgoraProviderData(
      appId: json['app_id'] ?? '',
      channelName: json['channel_name'] ?? '',
      token: json['token'] ?? '',
      uid: _parseInt(json['uid']) ?? 0,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'app_id': appId,
      'channel_name': channelName,
      'token': token,
      'uid': uid,
    };
  }
}

class CallUserInfo {
  final int userId;
  final String userName;
  final String userFirstname;
  final String userLastname;
  final String? userPicture;
  final bool? userIsOnline;

  CallUserInfo({
    required this.userId,
    required this.userName,
    required this.userFirstname,
    required this.userLastname,
    this.userPicture,
    this.userIsOnline,
  });

  factory CallUserInfo.fromJson(Map<String, dynamic> json) {
    return CallUserInfo(
      userId: _parseInt(json['user_id']) ?? 0,
      userName: json['user_name'] ?? '',
      userFirstname: json['user_firstname'] ?? '',
      userLastname: json['user_lastname'] ?? '',
      userPicture: json['user_picture'],
      userIsOnline: json['user_is_online'],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  String get fullName => '$userFirstname $userLastname'.trim();
}
