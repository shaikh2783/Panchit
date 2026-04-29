import 'package:snginepro/main.dart';
import 'package:flutter/foundation.dart';

/// نموذج الرسالة - مطابق لـ Backend API
class MessageModel {
  final int messageId;
  final int conversationId;
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatar;
  final String messageText;
  final String? image;
  final String? voiceNote;
  final DateTime sentAt;
  final bool isSeen;
  final bool isMe; // هل الرسالة من المستخدم الحالي

  MessageModel({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.messageText,
    this.avatar,
    this.image,
    this.voiceNote,
    required this.sentAt,
    this.isSeen = false,
    this.isMe = false,
  });

  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    // Helper function to safely convert any value to string (returns null for empty strings)
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is Map) return null; // Ignore nested maps
      final str = value.toString();
      return str.isEmpty ? null : str;
    }
    
    // Helper to build full URL for media files (images, audio, etc)
    String? _buildMediaUrl(dynamic value) {
      final mediaValue = _toStringOrNull(value);
      if (mediaValue == null) return null;
      
      // إذا كان URL كامل، ارجعه كما هو
      if (mediaValue.startsWith('http://') || mediaValue.startsWith('https://')) {
        return mediaValue;
      }
      
      // تنظيف المسار: إزالة / من البداية
      String cleanPath = mediaValue.startsWith('/') ? mediaValue.substring(1) : mediaValue;
      
      // إذا كان المسار لا يبدأ بـ content/، أضف content/uploads/
      if (!cleanPath.startsWith('content/')) {
        cleanPath = 'content/uploads/$cleanPath';
      }
      
      return '${cfgP.first['w1']}/$cleanPath';
    }

    final userId = int.tryParse(json['user_id']?.toString() ?? '0') ?? 0;
    final currentId = int.tryParse(currentUserId) ?? 0;
    
    final imageUrl = _buildMediaUrl(json['image']) ?? _buildMediaUrl(json['photo']);
    final voiceUrl = _buildMediaUrl(json['voice_note']) ?? _buildMediaUrl(json['audio']);
    final avatarUrl = _buildMediaUrl(json['user_picture']) ?? _buildMediaUrl(json['avatar']);
    
    if (imageUrl != null) {
    }
    if (voiceUrl != null) {
    }

    return MessageModel(
      messageId: int.tryParse(json['message_id']?.toString() ?? '0') ?? 0,
      conversationId: int.tryParse(json['conversation_id']?.toString() ?? '0') ?? 0,
      userId: userId,
      username: _toStringOrNull(json['user_name']) ?? _toStringOrNull(json['username']) ?? '',
      firstName: _toStringOrNull(json['user_firstname']) ?? _toStringOrNull(json['first_name']) ?? '',
      lastName: _toStringOrNull(json['user_lastname']) ?? _toStringOrNull(json['last_name']) ?? '',
      messageText: _toStringOrNull(json['message_decoded']) ?? _toStringOrNull(json['message']) ?? _toStringOrNull(json['text']) ?? '',
      avatar: avatarUrl,
      image: imageUrl,
      voiceNote: voiceUrl,
      sentAt: _parseSentAt(json['time'] ?? json['sent_at']),
      isSeen: json['seen'] == '1' || json['is_seen'] == true,
      isMe: userId == currentId,
    );
  }
static DateTime _parseSentAt(dynamic value) {
  if (value == null) return DateTime.now();

  if (value is DateTime) {
    return value.toLocal();
  }

  if (value is int) {
    if (value > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true).toLocal();
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return DateTime.now();

    final numeric = int.tryParse(trimmed);
    if (numeric != null) {
      if (numeric > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numeric, isUtc: true).toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(numeric * 1000, isUtc: true).toLocal();
    }

    try {
      final parsed = DateTime.parse(trimmed);
      final hasTimezone =
          trimmed.endsWith('Z') ||
          RegExp(r'([+-]\d{2}:\d{2})$').hasMatch(trimmed);

      if (hasTimezone) {
        return parsed.toLocal();
      }

      final utc = DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );

      return utc.toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  return DateTime.now();
}
  

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'conversation_id': conversationId,
      'user_id': userId,
      'user_name': username,
      'user_firstname': firstName,
      'user_lastname': lastName,
      'user_picture': avatar,
      'message': messageText,
      'image': image,
      'voice_note': voiceNote,
      'time': sentAt.toIso8601String(),
      'seen': isSeen,
    };
  }

  MessageModel copyWith({
    int? messageId,
    int? conversationId,
    int? userId,
    String? username,
    String? firstName,
    String? lastName,
    String? messageText,
    String? avatar,
    String? image,
    String? voiceNote,
    DateTime? sentAt,
    bool? isSeen,
    bool? isMe,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      messageText: messageText ?? this.messageText,
      avatar: avatar ?? this.avatar,
      image: image ?? this.image,
      voiceNote: voiceNote ?? this.voiceNote,
      sentAt: sentAt ?? this.sentAt,
      isSeen: isSeen ?? this.isSeen,
      isMe: isMe ?? this.isMe,
    );
  }

  // للتوافقية مع الكود القديم
  MessageType get messageType {
    if (image != null && image!.isNotEmpty) return MessageType.image;
    if (voiceNote != null && voiceNote!.isNotEmpty) return MessageType.voice;
    return MessageType.text;
  }

  String? get mediaUrl => image ?? voiceNote;
  String? get thumbnailUrl => image;
  bool get isSent => true;
}

enum MessageType {
  text,
  image,
  voice,
  video,
  file,
}
