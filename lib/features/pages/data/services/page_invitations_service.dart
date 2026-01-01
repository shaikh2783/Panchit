import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/invitable_friend.dart';

/// خدمة إدارة دعوات الصفحات
class PageInvitationsService {
  final ApiClient _apiClient;

  PageInvitationsService(this._apiClient);

  /// جلب الأصدقاء القابلين للدعوة إلى الصفحة
  Future<List<InvitableFriend>> getInvitableFriends({
    required int pageId,
    int offset = 0,
  }) async {
    try {

      final response = await _apiClient.get(
        configCfgP('page_invites_friends'),
        queryParameters: {
          'page_id': pageId.toString(),
          'offset': offset.toString(),
        },
      );

      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> friendsJson = response['data'] is List
            ? response['data']
            : [];
        final friends = friendsJson
            .map((json) => InvitableFriend.fromJson(json))
            .toList();

        return friends;
      }

      return [];
    } catch (e) {

      rethrow;
    }
  }

  /// جلب المديرين الحاليين للصفحة
  Future<List<InvitableFriend>> getPageAdmins({
    required int pageId,
    int offset = 0,
  }) async {
    try {

      final response = await _apiClient.get(
        configCfgP('page_admins').replaceAll('{id}', pageId.toString()),
        queryParameters: {
          'offset': offset.toString(),
        },
      );

      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> adminsJson = response['data'] is List
            ? response['data']
            : [];
        final admins = adminsJson
            .map((json) => InvitableFriend.fromJson(json))
            .toList();

        return admins;
      }

      return [];
    } catch (e) {

      rethrow;
    }
  }

  /// دعوة صديق إلى الصفحة
  Future<bool> inviteFriend({required int pageId, required int userId}) async {
    try {
      final endpoint = configCfgP(
        'pages_invite',
      ).replaceAll('{id}', pageId.toString());

      final response = await _apiClient.post(
        endpoint,
        body: {'user_id': userId},
      );

      if (response['status'] == 'success') {

        return true;
      }

      return false;
    } catch (e) {

      rethrow;
    }
  }

  /// جلب المعجبين بالصفحة (Page Likers/Fans)
  Future<List<InvitableFriend>> getPageLikers({
    required int pageId,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final endpoint = configCfgP('page_likers')
          .replaceAll('{id}', pageId.toString());

      final response = await _apiClient.get(
        endpoint,
        queryParameters: {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> likersJson = response['data'] is List
            ? response['data']
            : [];
        final likers = likersJson
            .map((json) => InvitableFriend.fromJson(json))
            .toList();

        return likers;
      }

      return [];
    } catch (e) {

      rethrow;
    }
  }

  /// دعوة عدة أصدقاء دفعة واحدة
  Future<bool> inviteFriends({
    required int pageId,
    required List<int> userIds,
  }) async {
    try {
      final endpoint = configCfgP(
        'pages_invite',
      ).replaceAll('{id}', pageId.toString());

      final response = await _apiClient.post(
        endpoint,
        body: {'users': userIds.map((id) => id.toString()).toList()},
      );

      if (response['status'] == 'success') {

        return true;
      }

      return false;
    } catch (e) {

      rethrow;
    }
  }
}
