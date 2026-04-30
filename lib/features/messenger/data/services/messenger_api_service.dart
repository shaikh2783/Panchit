import 'package:snginepro/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// خدمة API للماسنجر
/// مربوطة مع Backend Sngine
class MessengerApiService {
  final ApiClient _apiClient;

  MessengerApiService(this._apiClient);

  /// الحصول على قائمة المحادثات
  /// GET /chat/conversations?offset=0
  Future<List<ConversationModel>> getConversations({int offset = 0}) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations',
        queryParameters: {'offset': offset.toString()},
      );

      final data = response as Map<String, dynamic>? ?? {};
      
      if (data.isNotEmpty && data['status'] == 'success') {
        final List<dynamic> conversations = data['data'] ?? [];
        if (conversations.isNotEmpty) {
        }
        return conversations.map((json) => ConversationModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// الحصول على محادثة محددة أو إنشاء واحدة جديدة
  /// GET /chat/conversation?user_id=456
  Future<ConversationModel?> getOrCreateConversation({
    String? conversationId,
    String? userId,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (conversationId != null) queryParams['conversation_id'] = conversationId;
      if (userId != null) queryParams['user_id'] = userId;


      final response = await _apiClient.get(
        '/chat/conversation',
        queryParameters: queryParams,
      );

      final data = response as Map<String, dynamic>? ?? {};
      
      
      if (data.isNotEmpty && data['status'] == 'success') {
        final conversationData = data['data'];
        
        // Check if data is a List (array of conversations) or a single Map
        if (conversationData is List) {
          if (conversationData.isNotEmpty) {
            // If it's a list, take the first conversation
            return ConversationModel.fromJson(conversationData.first as Map<String, dynamic>);
          } else {
          }
        } else if (conversationData is Map<String, dynamic>) {
          // If it's a single conversation
          return ConversationModel.fromJson(conversationData);
        } else {
        }
      }
      
      return null;
    } catch (e, stackTrace) {
      return null;
    }
  }

  /// الحصول على رسائل محادثة معينة
  /// GET /chat/messages?conversation_id=123&offset=0&last_message_id=456
  Future<Map<String, dynamic>> getMessages({
    required String conversationId,
    required String currentUserId,
    int offset = 0,
    int? lastMessageId,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'conversation_id': conversationId,
        'offset': offset.toString(),
      };
      
      if (lastMessageId != null) {
        queryParams['last_message_id'] = lastMessageId.toString();
      }

      final response = await _apiClient.get(
        '/chat/messages',
        queryParameters: queryParams,
      );


      // Handle both Map and List responses
      if (response is List) {
        // Backend returned array directly
        final messages = response as List<dynamic>;
        
        return {
          'messages': messages
              .map((json) => MessageModel.fromJson(
                    json as Map<String, dynamic>,
                    currentUserId: currentUserId,
                  ))
              .toList(),
          'has_more': false,
          'typing_name_list': '',
          'seen_name_list': '',
          'user_is_online': false,
          'user_last_seen': null,
        };
      }

      if (response is! Map<String, dynamic>) {
        return {
          'messages': [],
          'has_more': false,
          'typing_name_list': '',
          'seen_name_list': '',
          'user_is_online': false,
        };
      }

      final respData = response as Map<String, dynamic>;

      if (respData.isNotEmpty && respData['status'] == 'success') {
        final data = respData['data'] as Map<String, dynamic>? ?? {};
        final List<dynamic> messages = data['messages'] ?? [];
        
        if (messages.isNotEmpty) {
          final firstMsg = messages.first as Map<String, dynamic>;
        }
        
        return {
          'messages': messages
              .map((json) => MessageModel.fromJson(
                    json as Map<String, dynamic>,
                    currentUserId: currentUserId,
                  ))
              .toList(),
          'has_more': data['has_more'] ?? false,
          'typing_name_list': data['typing_name_list'] ?? '',
          'seen_name_list': data['seen_name_list'] ?? '',
          'user_is_online': data['user_is_online'] ?? false,
          'user_last_seen': data['user_last_seen'],
        };
      }
      return {
        'messages': [],
        'has_more': false,
        'typing_name_list': '',
        'seen_name_list': '',
        'user_is_online': false,
      };
    } catch (e) {

      return {};
    }
  }

  /// إرسال رسالة نصية
  /// POST /chat/message
  Future<MessageModel?> sendMessage({
    required String conversationId,     // "0" means new conversation in your app
    required String messageText,
    required String currentUserId,
    required int otherUser,
  }) async {
    try {
      final bool isNewConversation = conversationId == "0";

      final int? convoIdAsInt = int.tryParse(conversationId);

      final Map<String, dynamic> requestData = {
        "conversation_id": isNewConversation ? null : convoIdAsInt,
        "message": messageText,
        'type': 'text',
        "recipients": isNewConversation ? <int>[otherUser] : null,
      };

      final response = await _apiClient.post(
        '/chat/message',
        data: requestData,
      );
      final respData = response as Map<String, dynamic>? ?? {};
      
      
      if (respData.isNotEmpty && respData['status'] == 'success') {
        final msgData = respData['data'] as Map<String, dynamic>? ?? {};
        
        return MessageModel.fromJson(
          msgData,
          currentUserId: currentUserId,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// إرسال صورة (بعد رفعها)
  /// POST /chat/message
  Future<MessageModel?> sendImage({
    required String conversationId,
    required String imageSource, // الرابط النسبي من الرفع: content/uploads/photos/...
    required String currentUserId,
  }) async {
    try {
      final requestData = {
        'conversation_id': conversationId,
        'photo': imageSource,
        'type': 'photo',
      };

      final response = await _apiClient.post(
        '/chat/message',
        data: requestData,
      );

      final data = response as Map<String, dynamic>? ?? {};
      
      if (data.isNotEmpty && data['status'] == 'success') {
        return MessageModel.fromJson(
          data['data'] as Map<String, dynamic>? ?? {},
          currentUserId: currentUserId,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// إرسال رسالة صوتية (بعد رفعها)
  /// POST /chat/message
  Future<MessageModel?> sendVoiceNote({
    required String conversationId,
    required String voiceSource, // الرابط النسبي من الرفع
    required String currentUserId,
  }) async {
    try {
      final requestData = {
        'conversation_id': conversationId,
        'voice_note': voiceSource,
        'type': 'voice',
      };

      final response = await _apiClient.post(
        '/chat/message',
        data: requestData,
      );

      final data = response as Map<String, dynamic>? ?? {};
      
      if (data.isNotEmpty && data['status'] == 'success') {
        return MessageModel.fromJson(
          data['data'] as Map<String, dynamic>? ?? {},
          currentUserId: currentUserId,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// تحديث حالة الكتابة
  /// POST /chat/reactions/typing
  Future<bool> updateTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/reactions/typing',
        data: {
          'conversation_id': conversationId,
          'is_typing': isTyping,
        },
      );

      final data = response as Map<String, dynamic>? ?? {};
      return data.isNotEmpty && data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  /// تحديد رسائل كمقروءة
  /// POST /chat/reactions/seen
  Future<bool> markMessagesAsSeen({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/reactions/seen',
        data: {
          'conversation_id': conversationId,
          'message_ids': messageIds.join(','),
        },
      );

      final data = response as Map<String, dynamic>? ?? {};
      return data.isNotEmpty && data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  /// حذف رسالة واحدة
  /// DELETE /chat/message/:id
  Future<bool> deleteMessage({
    required int messageId,
  }) async {
    try {
      final response = await _apiClient.delete('/chat/message/$messageId');
      return response.isEmpty ||
          response['status'] == 'success' ||
          response['callback'] == 1 ||
          response['callback'] == true;
    } catch (e) {
      return false;
    }
  }

  /// حذف محادثة
  /// POST /chat/reactions/delete
  Future<bool> deleteConversation({required String conversationId}) async {
    Future<bool> _post(String path) async {
      final response = await _apiClient.post(
        path,
        data: {'conversation_id': conversationId},
      );


      // Handle different response formats
      if (response is Map<String, dynamic>) {
        final data = response;
        // Accept success if status is success OR if callback is 1/true
        final ok = data['status'] == 'success' || 
                   data['callback'] == 1 || 
                   data['callback'] == true ||
                   (data.isEmpty == false && data['error'] == null);
        return ok;
      } else if (response is String) {
        // Some APIs return plain success string
        final ok = response.toString().contains('success');
        return ok;
      } else {
        return false;
      }
    }

    try {
      // المسار الموثق
      final primary = await _post('/chat/reactions/delete');
      if (primary) {
        return true;
      }

      // مسار بديل في حال إعداد مختلف في الخادم
      final fallback = await _post('/chat/conversation/delete');
      if (fallback) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// مغادرة محادثة جماعية
  /// POST /chat/reactions/leave
  Future<bool> leaveConversation({required String conversationId}) async {
    try {
      final response = await _apiClient.post(
        '/chat/reactions/leave',
        data: {'conversation_id': conversationId},
      );

      final data = response as Map<String, dynamic>? ?? {};
      return data.isNotEmpty && data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  /// جلب جهات الاتصال
  /// GET /chat/contacts?query=john&offset=0
  Future<List<Map>> getContacts({
    String? query,
    int offset = 0,
    List<int>? skippedIds,
  }) async {
    try {
      final Map<String, String> queryParams = {'offset': offset.toString()};
      if (query != null) queryParams['query'] = query;
      if (skippedIds != null && skippedIds.isNotEmpty) {
        queryParams['skipped_ids'] = skippedIds.join(',');
      }

      final response = await _apiClient.get(
        '/chat/contacts',
        queryParameters: queryParams,
      );
      
      final data = response as Map<String, dynamic>? ?? {};
      
      if (data.isNotEmpty && data['status'] == 'success') {
        final List<dynamic> conversations = data['data'] ?? [];
        return List<Map>.from(conversations);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// جلب المكالمات الواردة
  /// GET /chat/calls
  Future<List<Map>> getIncomingCalls() async {
    try {
      final response = await _apiClient.get('/chat/calls');

      final data = response as Map<String, dynamic>? ?? {};
      
      if (data.isNotEmpty && data['status'] == 'success') {
        final callsData = data['data'] as Map<String, dynamic>? ?? {};
        return List<Map>.from(callsData['calls'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// جلب الوسائط (صور/صوت) لمحادثة معينة عبر API مخصص
  /// GET /apis/php/data/chat/media?conversation_id=123&offset=0&limit=20
  Future<Map<String, dynamic>> getConversationMedia({
    required String conversationId,
    int offset = 0,
    int limit = 20,
    String? currentUserId,
  }) async {
    Future<Map<String, dynamic>> _fetch(String path) async {
      final response = await _apiClient.get(
        path,
        queryParameters: {
          'conversation_id': conversationId,
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> media = data['media'] as List<dynamic>? ?? [];
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      // Map media items to MessageModel for reuse in UI
      final items = media.map((m) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(m as Map);
        // Sender mapping if present
        if (json['sender'] is Map) {
          final s = Map<String, dynamic>.from(json['sender'] as Map);
          json['user_id'] = s['user_id'] ?? s['id'] ?? 0;
          json['username'] = s['username'] ?? s['user_name'] ?? '';
          json['first_name'] = s['first_name'] ?? s['user_firstname'] ?? '';
          json['last_name'] = s['last_name'] ?? s['user_lastname'] ?? '';
          json['avatar'] = s['avatar'] ?? s['user_picture'];
        }
        return MessageModel.fromJson(json, currentUserId: currentUserId ?? '0');
      }).toList();

      return {
        'items': items,
        'has_more': pagination['has_more'] == true,
        'pagination': pagination,
      };
    }

    try {
      // المسار الرسمي
      return await _fetch('/apis/php/data/chat/media');
    } catch (e) {
      // fallback للمسار القديم في حال إعداد الخادم مختلف
      try {
        return await _fetch('/data/chat/media');
      } catch (e2) {
        return {
          'items': <MessageModel>[],
          'has_more': false,
          'pagination': const {},
        };
      }
    }
  }

  /// جلب جميع الوسائط (صور/صوت) من كل المحادثات عبر API
  /// GET /apis/php/data/chat/media/all?offset=0&limit=20
  Future<Map<String, dynamic>> getAllMedia({
    int offset = 0,
    int limit = 20,
    String? currentUserId,
  }) async {
    Future<Map<String, dynamic>> _fetch(String path) async {
      final response = await _apiClient.get(
        path,
        queryParameters: {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> media = data['media'] as List<dynamic>? ?? [];
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      // Map media items to MessageModel
      final items = media.map((m) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(m as Map);
        // Sender mapping
        if (json['sender'] is Map) {
          final s = Map<String, dynamic>.from(json['sender'] as Map);
          json['user_id'] = s['user_id'] ?? s['id'] ?? 0;
          json['username'] = s['username'] ?? s['user_name'] ?? '';
          json['first_name'] = s['first_name'] ?? s['user_firstname'] ?? '';
          json['last_name'] = s['last_name'] ?? s['user_lastname'] ?? '';
          json['avatar'] = s['avatar'] ?? s['user_picture'];
        }
        return MessageModel.fromJson(json, currentUserId: currentUserId ?? '0');
      }).toList();

      return {
        'items': items,
        'has_more': pagination['has_more'] == true,
        'pagination': pagination,
      };
    }

    try {
      // المحاولة الأساسية مع المسار الصحيح
      return await _fetch('/apis/php/data/chat/media/all');
    } catch (e) {
      // fallback للمسار القديم في حال إعداد الخادم مختلف
      try {
        return await _fetch('/data/chat/media/all');
      } catch (e2) {
        return {
          'items': <MessageModel>[],
          'has_more': false,
          'pagination': const {},
        };
      }
    }
  }
}
