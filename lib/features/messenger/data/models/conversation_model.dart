import 'package:snginepro/main.dart';

/// نموذج المحادثة - مطابق لـ Backend API
class ConversationModel {
  final String conversationId; // String للتوافق مع البيانات التجريبية
  final int nodeId;
  final String nodeType; // user, page, group
  final UserPreview otherUser;
  final String? lastMessage;
  final String? lastMessageType; // image, voice, text, video, file
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final int messagesCount;
  final bool isSeen;
  final bool isTyping;

  ConversationModel({
    required this.conversationId,
    this.nodeId = 0,
    this.nodeType = 'user',
    required this.otherUser,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
    this.messagesCount = 0,
    this.isSeen = false,
    this.isTyping = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert any value to string
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is Map) return null; // Ignore nested maps
      return value.toString();
    }

    final conversationIdStr = _toStringOrNull(json['conversation_id']) ?? _toStringOrNull(json['id']) ?? '';
    
    // البحث عن نص آخر رسالة في عدة حقول محتملة
    final lastMessage = _toStringOrNull(json['last_message_decoded']) ?? 
                       _toStringOrNull(json['last_message']) ?? 
                       _toStringOrNull(json['message']) ??
                       _toStringOrNull(json['text']);
    
    return ConversationModel(
      conversationId: conversationIdStr,
      nodeId: int.tryParse(json['node_id']?.toString() ?? '0') ?? 0,
      nodeType: _toStringOrNull(json['node_type']) ?? 'user',
      otherUser: UserPreview.fromJson(json),
      lastMessage: lastMessage,
      lastMessageType: _toStringOrNull(json['last_message_type']),
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'].toString())
          : null,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      isOnline: json['user_is_online'] == true || json['user_is_online'] == '1',
      lastSeen: json['user_last_seen'] != null
          ? DateTime.tryParse(json['user_last_seen'].toString())
          : null,
      messagesCount: int.tryParse(json['messages_count']?.toString() ?? '0') ?? 0,
      isSeen: json['seen'] == true || json['seen'] == '1',
      isTyping: json['is_typing'] == true || json['is_typing'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'node_id': nodeId,
      'node_type': nodeType,
      'user': otherUser.toJson(),
      'last_message': lastMessage,
      'last_message_type': lastMessageType,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'user_is_online': isOnline,
      'user_last_seen': lastSeen?.toIso8601String(),
      'messages_count': messagesCount,
      'seen': isSeen,
      'is_typing': isTyping,
    };
  }
}

/// معلومات مختصرة عن المستخدم - من Conversation API
class UserPreview {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? avatar;
  final String? avatarFull;
  final bool isVerified;
  final String? link; // profile link

  UserPreview({
    required this.userId,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    String? fullName,
    this.avatar,
    this.avatarFull,
    this.isVerified = false,
    this.link,
  }) : fullName = fullName ?? '$firstName $lastName'.trim();

  factory UserPreview.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert any value to string
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is Map) return null; // Ignore nested maps
      return value.toString();
    }
    
    // Helper to build full URL for avatar
    String? _buildAvatarUrl(dynamic value) {
      final avatarValue = _toStringOrNull(value);
      if (avatarValue == null) return null;
      
      // إذا كان URL كامل، ارجعه كما هو
      if (avatarValue.startsWith('http://') || avatarValue.startsWith('https://')) {
        return avatarValue;
      }
      
      // تنظيف المسار: إزالة / من البداية
      String cleanPath = avatarValue.startsWith('/') ? avatarValue.substring(1) : avatarValue;
      
      // إذا كان المسار لا يبدأ بـ content/، أضف content/uploads/
      if (!cleanPath.startsWith('content/')) {
        cleanPath = 'content/uploads/$cleanPath';
      }
      
      return '${cfgP.first['w1']}/$cleanPath';
    }

    final avatarUrl = _buildAvatarUrl(json['user_picture']) ?? 
                      _buildAvatarUrl(json['avatar']) ?? 
                      _buildAvatarUrl(json['user_avatar']) ??
                      _buildAvatarUrl(json['picture']) ??
                      _buildAvatarUrl(json['profile_picture']);

    return UserPreview(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: _toStringOrNull(json['user_name']) ?? _toStringOrNull(json['username']) ?? '',
      firstName: _toStringOrNull(json['user_firstname']) ?? _toStringOrNull(json['first_name']) ?? '',
      lastName: _toStringOrNull(json['user_lastname']) ?? _toStringOrNull(json['last_name']) ?? '',
      fullName: _toStringOrNull(json['name']) ?? _toStringOrNull(json['user_fullname']) ?? _toStringOrNull(json['full_name']) ?? '',
      avatar: avatarUrl,
      avatarFull: _buildAvatarUrl(json['conversation_picture']),
      isVerified: json['user_verified'] == '1' || json['is_verified'] == true,
      link: _toStringOrNull(json['link']) ?? _toStringOrNull(json['username']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'avatar': avatar,
      'avatar_full': avatarFull,
      'is_verified': isVerified,
      'link': link,
    };
  }
}
