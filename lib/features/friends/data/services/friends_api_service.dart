import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/friendship_model.dart';

/// خدمة API شاملة لإدارة الأصدقاء والمتابعة
class FriendsApiService {
  final ApiClient _apiClient;
  
  FriendsApiService(this._apiClient);
  
  // ========================================
  // 🤝 Friend Management APIs
  // ========================================
  
  /// إرسال طلب صداقة
  Future<FriendActionResult> sendFriendRequest(int userId) async {
    try {
      final response = await _apiClient.post(
        configCfgP('friends_add'),
        body: {'user_id': userId},
      );
      
      
      if (response['status'] == 'success') {
        return FriendActionResult.success(
          response['message'] ?? 'Friend request sent successfully',
          FriendshipStatus.pending,
        );
      } else {
        return FriendActionResult.error(
          response['message'] ?? 'Failed to send friend request',
          FriendshipStatus.none,
        );
      }
    } catch (e) {
      return FriendActionResult.error(
        'Failed to send friend request',
        FriendshipStatus.none,
      );
    }
  }
  
  /// إلغاء طلب صداقة مرسل
  Future<FriendActionResult> cancelFriendRequest(int userId) async {
    try {
      // ✅ استخدام endpoint المخصص لإلغاء الطلب المرسل
      final response = await _apiClient.post(
        configCfgP('friends_cancel'),
        body: {'user_id': userId},
      );
      
      if (response['status'] == 'success') {
        return FriendActionResult.success(
          response['message'] ?? 'Friend request cancelled',
          FriendshipStatus.none,
        );
      } else {
        return FriendActionResult.error(
          response['message'] ?? 'Failed to cancel friend request',
          FriendshipStatus.pending,
        );
      }
    } catch (e) {
      return FriendActionResult.error(
        'Failed to cancel friend request',
        FriendshipStatus.pending,
      );
    }
  }

  /// قبول طلب صداقة
  Future<FriendActionResult> acceptFriendRequest(int userId) async {
    try {
      // ✅ استخدام endpoint المخصص لقبول الطلبات
      final response = await _apiClient.post(
        configCfgP('friends_accept'),
        body: {'user_id': userId},
      );
      
      if (response['status'] == 'success') {
        return FriendActionResult.success(
          response['message'] ?? 'Friend request accepted',
          FriendshipStatus.friends,
        );
      } else {
        return FriendActionResult.error(
          response['message'] ?? 'Failed to accept friend request',
          FriendshipStatus.requested,
        );
      }
    } catch (e) {
      return FriendActionResult.error(
        'Failed to accept friend request',
        FriendshipStatus.requested,
      );
    }
  }

  /// رفض طلب صداقة
  Future<FriendActionResult> declineFriendRequest(int userId) async {
    try {
      // ✅ استخدام endpoint المخصص لرفض الطلب الوارد
      final response = await _apiClient.post(
        configCfgP('friends_decline'),
        body: {'user_id': userId},
      );
      
      if (response['status'] == 'success') {
        return FriendActionResult.success(
          response['message'] ?? 'Friend request declined',
          FriendshipStatus.none,
        );
      } else {
        return FriendActionResult.error(
          response['message'] ?? 'Failed to decline friend request',
          FriendshipStatus.requested,
        );
      }
    } catch (e) {
      return FriendActionResult.error(
        'Failed to decline friend request',
        FriendshipStatus.requested,
      );
    }
  }

  /// إزالة صديق (إنهاء الصداقة)
  Future<FriendActionResult> removeFriend(int userId) async {
    try {
      final response = await _apiClient.post(
        configCfgP('friends_remove'),
        body: {'user_id': userId},
      );
      
      if (response['status'] == 'success') {
        return FriendActionResult.success(
          response['message'] ?? 'Friend removed successfully',
          FriendshipStatus.none,
        );
      } else {
        return FriendActionResult.error(
          response['message'] ?? 'Failed to remove friend',
          FriendshipStatus.friends,
        );
      }
    } catch (e) {
      return FriendActionResult.error(
        'Failed to remove friend',
        FriendshipStatus.friends,
      );
    }
  }

  /// جلب طلبات الصداقة الواردة
  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    try {
      final response = await _apiClient.get(configCfgP('friends_requests'));
      
      if (response['status'] == 'success') {
        final data = response['data']['friend_requests'] as List;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// جلب طلبات الصداقة المرسلة
  Future<List<Map<String, dynamic>>> getSentFriendRequests() async {
    try {
      final response = await _apiClient.get(configCfgP('friends_sent'));
      
      if (response['status'] == 'success') {
        final data = response['data']['sent_requests'] as List;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ========================================
  // 👥 Follow Management APIs
  // ========================================
  
  /// متابعة مستخدم
  Future<FriendActionResult> followUser(int userId) async {
    try {
      final response = await _apiClient.post(
        configCfgP('users_follow'),
        body: {'user_id': userId},
      );
      
      if (response['status'] == 'success') {
        return FriendActionResult.success(
          response['message'] ?? 'Now following user',
          FriendshipStatus.following,
        );
      } else {
        return FriendActionResult.error(
          response['message'] ?? 'Failed to follow user',
          FriendshipStatus.none,
        );
      }
    } catch (e) {
      return FriendActionResult.error(
        'Failed to follow user',
        FriendshipStatus.none,
      );
    }
  }
  
  /// إلغاء متابعة مستخدم
  Future<FriendActionResult> unfollowUser(int userId) async {
    try {
      final response = await _apiClient.post(
        configCfgP('users_unfollow'),
        body: {'user_id': userId},
      );
      
      if (response['status'] == 'success') {
        return FriendActionResult.success(
          response['message'] ?? 'Unfollowed user',
          FriendshipStatus.none,
        );
      } else {
        return FriendActionResult.error(
          response['message'] ?? 'Failed to unfollow user',
          FriendshipStatus.following,
        );
      }
    } catch (e) {
      return FriendActionResult.error(
        'Failed to unfollow user',
        FriendshipStatus.following,
      );
    }
  }

  // ========================================
  // 🌍 Public APIs (للزوار والمسجلين)
  // ========================================

  /// الحصول على حالة العلاقة (عام - للزوار والمسجلين)
  Future<Map<String, dynamic>?> getUserRelationshipStatus(int userId) async {
    try {
      final response = await _apiClient.get(configCfgP('user_base') + '/$userId/relationship');
      
      if (response['status'] == 'success') {
        return response['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// الحصول على الملف الشخصي العام (للزوار والمسجلين)
  Future<Map<String, dynamic>?> getPublicUserProfile(String username) async {
    try {
      final response = await _apiClient.get(configCfgP('user_base') + '/$username/profile');
      
      if (response['status'] == 'success') {
        return response['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
