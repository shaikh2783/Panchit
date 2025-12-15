import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/event.dart';
import '../models/event_member.dart';
import '../models/event_category.dart';
/// خدمة إدارة الفعاليات
class EventsService {
  final ApiClient _apiClient;
  EventsService(this._apiClient);
  /// جلب تصنيفات الفعاليات
  Future<List<EventCategory>> getEventCategories() async {
    try {
      final response = await _apiClient.get(configCfgP('events_categories'));
      if (response['status'] == 'success') {
        final data = response['data']['categories'] as List? ?? [];
        return data.map((c) => EventCategory.fromJson(c)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  /// 1️⃣ البحث عن فعاليات
  Future<Map<String, dynamic>> searchEvents({
    required String query,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('search'),
        queryParameters: {
          'query': query,
          'tab': 'events',
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );
      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        final events = results.map((e) => Event.fromJson(e)).toList();
        return {
          'status': 'success',
          'events': events,
          'total': events.length,
        };
      }
      return {'status': 'error', 'message': 'Failed to search events'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 2️⃣ إنشاء فعالية جديدة
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String location,
    required String description,
    required int categoryId,
    required String startDate,
    required String endDate,
    required String privacy,
    required bool isOnline,
    String? eventPicture,
    String? eventCover,
    int? country,
    int? language,
  }) async {
    try {
      final body = {
        'title': title,
        'location': location,
        'description': description,
        'category': categoryId.toString(),
        'start_date': startDate,
        'end_date': endDate,
        'privacy': privacy,
        'is_online': isOnline,
        if (eventPicture != null) 'event_picture': eventPicture,
        if (eventCover != null) 'event_cover': eventCover,
        if (country != null) 'country': country.toString(),
        if (language != null) 'language': language.toString(),
      };
      return await _apiClient.post(configCfgP('events_base') + '/create', body: body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 3️⃣ جلب معلومات فعالية
  Future<Map<String, dynamic>> getEvent(int eventId) async {
    try {
      final response = await _apiClient.get(configCfgP('events_base') + '/$eventId');
      if (response['status'] == 'success') {
        final event = Event.fromJson(response['data']);
        return {
          'status': 'success',
          'event': event,
        };
      }
      return {'status': 'error', 'message': 'Failed to get event'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 4️⃣ تعديل فعالية
  Future<Map<String, dynamic>> updateEvent({
    required int eventId,
    String? title,
    String? description,
    String? location,
    int? categoryId,
    String? startDate,
    String? endDate,
    String? privacy,
    bool? isOnline,
    int? country,
    int? language,
    String? eventPicture,
    String? eventCover,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (location != null) body['location'] = location;
      if (categoryId != null) body['category'] = categoryId;
      if (startDate != null) body['start_date'] = startDate;
      if (endDate != null) body['end_date'] = endDate;
      if (privacy != null) body['privacy'] = privacy;
      if (isOnline != null) body['is_online'] = isOnline;
      if (country != null) body['country'] = country.toString();
      if (language != null) body['language'] = language.toString();
      if (eventPicture != null) body['event_picture'] = eventPicture;
      if (eventCover != null) body['event_cover'] = eventCover;
      // Try PUT first (RESTful standard for updates)
      try {
        final response = await _apiClient.put(configCfgP('events_base') + '/$eventId/update', body: body);
        return response;
      } catch (e) {
        // Fallback to POST if PUT fails
        final response = await _apiClient.post(configCfgP('events_base') + '/$eventId/update', body: body);
        return response;
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 5️⃣ حذف فعالية
  Future<Map<String, dynamic>> deleteEvent(int eventId) async {
    try {
      return await _apiClient.post(configCfgP('events_base') + '/$eventId/delete');
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 6️⃣ الانضمام لفعالية
  Future<Map<String, dynamic>> joinEvent({
    required int eventId,
    String action = 'going', // going, interested
  }) async {
    try {
      return await _apiClient.post(
        configCfgP('events_base') + '/$eventId/join',
        body: {'action': action},
      );
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 7️⃣ مغادرة فعالية
  Future<Map<String, dynamic>> leaveEvent(int eventId) async {
    try {
      return await _apiClient.post(configCfgP('events_base') + '/$eventId/leave');
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 8️⃣ جلب أعضاء فعالية
  Future<Map<String, dynamic>> getEventMembers({
    required int eventId,
    String? type, // going, interested, invited
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };
      final response = await _apiClient.get(
        configCfgP('events_base') + '/$eventId/members',
        queryParameters: queryParams,
      );
      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        final membersList = (data['members'] as List? ?? [])
            .map((m) => EventMember.fromJson(m as Map<String, dynamic>))
            .toList();
        return {
          'status': 'success',
          'members': membersList,
          'total': data['total'] ?? 0,
          'hasMore': membersList.length >= limit,
        };
      }
      return {'status': 'error', 'message': 'Failed to get members'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 9️⃣ دعوة أصدقاء
  Future<Map<String, dynamic>> inviteFriends({
    required int eventId,
    required List<int> userIds,
  }) async {
    try {
      // ✅ استخدم الـ endpoint الجديد /invites/send
      final body = userIds.length == 1
          ? {'user_id': userIds.first}
          : {'user_ids': userIds};
      final response = await _apiClient.post(
        configCfgP('events_base') + '/$eventId/invites/send',
        body: body,
      );
      if (response['status'] == 'success') {
        final data = response['data'];
        final invitedCount = data['invited_count'] ?? 0;
        return {
          'status': 'success',
          'message': response['message'] ?? 
              (invitedCount == 1 
                  ? 'تمت دعوة الصديق بنجاح'
                  : 'تمت دعوة $invitedCount أصدقاء بنجاح'),
          'data': data,
        };
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'فشلت الدعوة',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 🔟 جلب منشورات فعالية
  Future<Map<String, dynamic>> getEventPosts({
    required int eventId,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('events_base') + '/$eventId/posts',
        queryParameters: {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );
      if (response['status'] == 'success') {
        final dataObj = response['data'];
        // Check if data contains posts array
        if (dataObj is Map<String, dynamic> && dataObj.containsKey('posts')) {
          final postsList = dataObj['posts'] as List? ?? [];
          final totalValue = dataObj['total'] ?? postsList.length;
          return {
            'status': 'success',
            'data': postsList,
            'total': totalValue is int ? totalValue : int.tryParse(totalValue.toString()) ?? postsList.length,
          };
        }
        // Fallback: if data is already a list
        if (dataObj is List) {
          return {
            'status': 'success',
            'data': dataObj,
            'total': dataObj.length,
          };
        }
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'Failed to load event posts',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 1️⃣1️⃣ جلب فعالياتي
  Future<Map<String, dynamic>> getMyEvents({
    String? filter, // admin, going, interested, invited
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        if (filter != null) 'filter': filter,
      };
      final response = await _apiClient.get(
        configCfgP('events_base') + '/my',
        queryParameters: queryParams,
      );
      if (response['status'] == 'success') {
        // API returns data in 'data.results'
        final dataObj = response['data'];
        final eventsList = dataObj['results'] as List? ?? [];
        final events = eventsList
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList();
        return {
          'status': 'success',
          'events': events,
          'total': dataObj['total'] ?? events.length,
        };
      }
      return {'status': 'error', 'message': 'Failed to get my events'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// 1️⃣2️⃣ فعاليات مقترحة
  Future<Map<String, dynamic>> getSuggestedEvents({
    int? categoryId,
    String? type, // online, in_person
    String? country,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (type != null) 'type': type,
        if (country != null) 'country': country,
      };
      final response = await _apiClient.get(
        configCfgP('events_base') + '/suggested',
        queryParameters: queryParams,
      );
      if (response['status'] == 'success') {
        // API returns data in 'data.results'
        final dataObj = response['data'];
        final eventsList = dataObj['results'] as List? ?? [];
        final events = eventsList
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList();
        return {
          'status': 'success',
          'events': events,
          'total': dataObj['total'] ?? events.length,
        };
      }
      return {'status': 'error', 'message': 'Failed to get suggested events'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// تحديث صورة الفعالية (Event Picture)
  Future<Map<String, dynamic>> updateEventPicture({
    required int eventId,
    required String pictureData, // base64 or URL
  }) async {
    try {
      final response = await _apiClient.post(
        '/data/events/$eventId/picture',
        data: {'picture': pictureData},
      );
      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        return {
          'status': 'success',
          'event_picture': data['event_picture'],
          'event': Event.fromJson(data['event']),
        };
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'Failed to update event picture'
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  /// تحديث غلاف الفعالية (Event Cover)
  Future<Map<String, dynamic>> updateEventCover({
    required int eventId,
    required String coverData, // base64 or URL
  }) async {
    try {
      final response = await _apiClient.post(
        '/data/events/$eventId/cover',
        data: {'cover': coverData},
      );
      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        return {
          'status': 'success',
          'event_cover': data['event_cover'],
          'event': Event.fromJson(data['event']),
        };
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'Failed to update event cover'
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
