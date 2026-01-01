import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/profile/data/models/user_video.dart';
import 'package:flutter/foundation.dart';

class UserVideosService {
  final ApiClient _apiClient;

  UserVideosService(this._apiClient);

  /// جلب فيديوهات المستخدم
  /// 
  /// [userId] - معرف المستخدم (اختياري - بدونها يستخدم المستخدم الحالي)
  /// [username] - اسم المستخدم (اختياري - يُستخدم إذا لم يكن userId متاحاً)
  /// [offset] - رقم البداية للنتائج
  /// [limit] - عدد النتائج المطلوبة
  Future<List<UserVideo>> getUserVideos({
    int? userId,
    String? username,
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      
      final params = <String, String>{
        'offset': offset.toString(),
        'limit': limit.toString(),
      };

      if (userId != null) {
        params['user_id'] = userId.toString();
      } else if (username != null) {
        params['username'] = username;
      }


      final response = await _apiClient.get(
        'data/user/videos',
        queryParameters: params,
      );


      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        final videosList = data['videos'] as List?;
        
        final videos = videosList
            ?.map((v) => UserVideo.fromJson(v as Map<String, dynamic>))
            .toList() ?? [];
        
        return videos;
      } else {
        throw Exception(response['message'] ?? 'Failed to load videos');
      }
    } catch (e, stackTrace) {
      throw Exception('Error loading user videos: $e');
    }
  }
}