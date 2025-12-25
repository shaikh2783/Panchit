import 'package:snginepro/core/network/api_client.dart';
import '../models/blocked_user.dart';

class BlockingService {
  final ApiClient _apiClient;
  BlockingService(this._apiClient);

  Future<Map<String, dynamic>> getBlockedUsers({int page = 1, int limit = 20}) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final resp = await _apiClient.get('/data/users/blocked', queryParameters: params);
    final data = resp['data'] ?? {};
    final users = (data['blocked_users'] as List? ?? [])
        .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
        .toList();
    return {
      'blockedUsers': users,
      'pagination': data['pagination'] ?? {},
      'message': resp['message'] ?? 'Blocked users retrieved successfully',
    };
  }

  Future<Map<String, dynamic>> blockUser({required int userId}) async {
    final body = {'user_id': userId};
    final resp = await _apiClient.post('/data/users/block', body: body);
    return resp;
  }

  Future<Map<String, dynamic>> unblockUser({required int userId}) async {
    final body = {'user_id': userId};
    final resp = await _apiClient.post('/data/users/unblock', body: body);
    return resp;
  }

  Future<bool> checkUserBlocked({required int userId}) async {
    final params = {'user_id': userId.toString()};
    final resp = await _apiClient.get('/data/users/check-blocked', queryParameters: params);
    final data = resp['data'] ?? {};
    return data['is_blocked'] == true;
  }
}
