import 'package:snginepro/core/network/api_client.dart';
import '../models/follower.dart';
import '../models/subscription.dart';

class UserRelationshipsService {
  final ApiClient _apiClient;

  UserRelationshipsService(this._apiClient);

  /// Get Friends List
  Future<Map<String, dynamic>> getFriends({
    int? userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (userId != null) {
        params['user_id'] = userId.toString();
      }


      final response = await _apiClient.get(
        '/data/users/friends',
        queryParameters: params,
      );

      final friendsList = (response['data']['friends'] as List? ?? [])
          .map((json) => Follower.fromJson(json as Map<String, dynamic>))
          .toList();


      return {
        'friends': friendsList,
        'pagination': response['data']['pagination'] ?? {},
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get Followers List
  Future<Map<String, dynamic>> getFollowers({
    int? userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (userId != null) {
        params['user_id'] = userId.toString();
      }


      final response = await _apiClient.get(
        '/data/users/followers',
        queryParameters: params,
      );

      final followersList = (response['data']['followers'] as List? ?? [])
          .map((json) => Follower.fromJson(json as Map<String, dynamic>))
          .toList();


      return {
        'followers': followersList,
        'pagination': response['data']['pagination'] ?? {},
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get Followings List
  Future<Map<String, dynamic>> getFollowings({
    int? userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (userId != null) {
        params['user_id'] = userId.toString();
      }


      final response = await _apiClient.get(
        '/data/users/followings',
        queryParameters: params,
      );

      final followingsList = (response['data']['followings'] as List? ?? [])
          .map((json) => Follower.fromJson(json as Map<String, dynamic>))
          .toList();


      return {
        'followings': followingsList,
        'pagination': response['data']['pagination'] ?? {},
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get Subscriptions List
  Future<Map<String, dynamic>> getSubscriptions({
    int? userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (userId != null) {
        params['user_id'] = userId.toString();
      }


      final response = await _apiClient.get(
        '/data/users/subscriptions',
        queryParameters: params,
      );

      final subscriptionsList =
          (response['data']['subscriptions'] as List? ?? [])
              .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
              .toList();


      return {
        'subscriptions': subscriptionsList,
        'pagination': response['data']['pagination'] ?? {},
      };
    } catch (e) {
      rethrow;
    }
  }
}
