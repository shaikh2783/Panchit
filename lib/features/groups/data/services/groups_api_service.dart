import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../feed/data/models/posts_response.dart';
import '../models/groups_response.dart';
import '../models/group.dart';
import '../models/group_member_request.dart';
import '../models/group_member.dart';
import '../models/group_category.dart';
import '../../../../core/models/country.dart';
import '../../../../core/models/language.dart';

/// خدمة API للمجموعات
class GroupsApiService {
  final ApiClient _apiClient;

  GroupsApiService(this._apiClient);

  /// جلب جميع tabs في طلب واحد (endpoint المجمّع الجديد)
  Future<GroupsOverviewResponse> getAllTabs() async {
    try {
      final response = await _apiClient.get(configCfgP('user_groups_all_tabs'));

      return GroupsOverviewResponse.fromJson(response);
    } catch (e) {

      rethrow;
    }
  }

  /// جلب المجموعات المنضم إليها
  Future<GroupsResponse> getJoinedGroups({
    int page = 1,
    int limit = 20,
    String status = 'approved',
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('user_groups'),
        queryParameters: {
          'status': status,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      return GroupsResponse.fromJson(response);
    } catch (e) {

      rethrow;
    }
  }

  /// جلب المجموعات المُدارة
  Future<GroupsResponse> getManagedGroups({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('user_groups_managed'),
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      return GroupsResponse.fromJson(response);
    } catch (e) {

      rethrow;
    }
  }

  /// جلب المجموعات المقترحة
  Future<GroupsResponse> getSuggestedGroups({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('groups_suggested'),
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      return GroupsResponse.fromJson(response);
    } catch (e) {

      rethrow;
    }
  }

  /// البحث في المجموعات
  Future<GroupsResponse> searchGroups({
    required String query,
    int? categoryId,
    String? privacy,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'search': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (categoryId != null) {
        queryParams['category'] = categoryId.toString();
      }

      if (privacy != null) {
        queryParams['privacy'] = privacy;
      }

      final response = await _apiClient.get(
        configCfgP('groups'),
        queryParameters: queryParams,
      );

      return GroupsResponse.fromJson(response);
    } catch (e) {

      rethrow;
    }
  }

  /// جلب تفاصيل مجموعة
  Future<Group?> getGroupDetails(int groupId) async {
    try {

      final response = await _apiClient.get('${configCfgP('groups')}/$groupId');

      final groupResponse = GroupResponse.fromJson(response);
      return groupResponse.group;
    } catch (e) {

      return null;
    }
  }

  /// الانضمام لمجموعة
  Future<bool> joinGroup(int groupId) async {
    try {
      final response = await _apiClient.post(
        '${configCfgP('groups')}/$groupId/join',
      );

      return response['status'] == 'success';
    } catch (e) {

      return false;
    }
  }

  /// مغادرة مجموعة
  Future<bool> leaveGroup(int groupId) async {
    try {
      final response = await _apiClient.post(
        '${configCfgP('groups')}/$groupId/leave',
      );

      return response['status'] == 'success';
    } catch (e) {

      return false;
    }
  }

  /// إنشاء مجموعة
  Future<Map<String, dynamic>?> createGroup({
    required String title,
    required String username,
    required String privacy,
    required int categoryId,
    String? description,
    int? countryId,
    int? languageId,
  }) async {
    try {
      final body = {
        'title': title,
        'username': username,
        'privacy': privacy,
        'category': categoryId,
      };

      if (description != null) body['description'] = description;
      if (countryId != null) body['country'] = countryId;
      if (languageId != null) body['language'] = languageId;

      final response = await _apiClient.post(configCfgP('groups'), body: body);

      if (response['status'] == 'success') {
        return response['data'];
      }
      return null;
    } catch (e) {

      return null;
    }
  }

  /// تحديث مجموعة
  Future<bool> updateGroup({
    required int groupId,
    String? title,
    String? username,
    String? description,
    String? privacy,
    int? categoryId,
    int? countryId,
    int? languageId,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (title != null) body['title'] = title;
      if (username != null) body['username'] = username;
      if (description != null) body['description'] = description;
      if (privacy != null) body['privacy'] = privacy;
      if (categoryId != null) body['category'] = categoryId;
      if (countryId != null) body['country'] = countryId;
      if (languageId != null) body['language'] = languageId;

      final response = await _apiClient.put(
        '${configCfgP('groups')}/$groupId',
        body: body,
      );

      return response['status'] == 'success';
    } catch (e) {

      return false;
    }
  }

  /// حذف مجموعة
  Future<bool> deleteGroup(int groupId) async {
    try {
      // استخدام POST /data/groups/delete مع group_id (مثل Pages API)
      final response = await _apiClient.post(
        '${configCfgP('groups')}/delete',
        body: {'group_id': groupId},
      );

      return response['status'] == 'success';
    } catch (e) {

      return false;
    }
  }

  /// جلب منشورات مجموعة
  Future<PostsResponse> fetchGroupPosts({
    required int groupId,
    int limit = 10,
    int offset = 0,
  }) async {

    final response = await _apiClient.get(
      configCfgP('groups_posts'),
      queryParameters: {
        'group_id': '$groupId',
        'offset': '$offset',
        'limit': '$limit',
      },
    );

    final postsResponse = PostsResponse.fromJson(response);

    if (!postsResponse.isSuccess) {
      throw Exception(postsResponse.message ?? 'Failed to fetch group posts');
    }

    return postsResponse;
  }

  /// جلب طلبات الانضمام المعلقة (للمشرف فقط)
  Future<List<GroupMemberRequest>> getPendingRequests(int groupId) async {
    try {

      final response = await _apiClient.get(
        '${configCfgP('groups')}/$groupId/requests',
      );

      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        final requestsList = data['requests'] as List<dynamic>;

        if (requestsList.isNotEmpty) {

        }

        return requestsList
            .map((json) => GroupMemberRequest.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {

      rethrow;
    }
  }

  /// قبول طلب انضمام عضو
  Future<bool> acceptMemberRequest(int groupId, int userId) async {
    try {
      final response = await _apiClient.post(
        '${configCfgP('groups')}/$groupId/members/$userId/accept',
      );

      return response['status'] == 'success';
    } catch (e) {

      return false;
    }
  }

  /// رفض طلب انضمام عضو
  Future<bool> declineMemberRequest(int groupId, int userId) async {
    try {
      final response = await _apiClient.post(
        '${configCfgP('groups')}/$groupId/members/$userId/decline',
      );

      return response['status'] == 'success';
    } catch (e) {

      return false;
    }
  }

  // ========================================
  // Helper Data Methods
  // ========================================

  /// جلب فئات المجموعات
  Future<List<GroupCategory>> getGroupCategories() async {
    try {
      final response = await _apiClient.get(configCfgP('groups_categories'));

      if (response['status'] == 'success') {
        final data = response['data']['categories'] as List? ?? [];
        return data.map((c) => GroupCategory.fromJson(c)).toList();
      }

      return [];
    } catch (e) {

      return [];
    }
  }

  /// جلب قائمة الدول
  Future<List<Country>> getCountries() async {
    try {
      final response = await _apiClient.get(configCfgP('countries'));

      if (response['status'] == 'success') {
        final data = response['data']['countries'] as List? ?? [];
        return data.map((c) => Country.fromJson(c)).toList();
      }

      return [];
    } catch (e) {

      return [];
    }
  }

  /// جلب قائمة اللغات
  Future<List<Language>> getLanguages() async {
    try {
      final response = await _apiClient.get(configCfgP('languages'));

      if (response['status'] == 'success') {
        final data = response['data']['languages'] as List? ?? [];
        return data.map((c) => Language.fromJson(c)).toList();
      }

      return [];
    } catch (e) {

      return [];
    }
  }

  /// Get group members with pagination and status filter
  Future<GroupMembersResponse> getMembers(
    int groupId, {
    String status = 'approved', // 'approved', 'pending', or 'all'
    int page = 1,
    int limit = 20,
  }) async {
    try {

      final response = await _apiClient.get(
        '/data/groups/$groupId/members',
        queryParameters: {
          'status': status,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response['status'] == 'success') {

        return GroupMembersResponse.fromJson(response['data']);
      }

      throw Exception(response['message'] ?? 'Failed to fetch members');
    } catch (e) {

      rethrow;
    }
  }

  /// Remove a member from the group (admin only)
  Future<bool> removeMember(int groupId, int userId) async {
    try {

      final response = await _apiClient.post(
        '/data/groups/$groupId/members/$userId/remove',
        body: {},
      );

      if (response['status'] == 'success') {

        return true;
      }

      throw Exception(response['message'] ?? 'Failed to remove member');
    } catch (e) {

      rethrow;
    }
  }

  /// Make a member admin (admin/owner only)
  /// TODO: Waiting for backend endpoint implementation
  /// Expected endpoint: POST /data/groups/:id/members/:user_id/make-admin
  Future<bool> makeAdmin(int groupId, int userId) async {
    try {

      // TODO: Update endpoint when backend is ready
      final response = await _apiClient.post(
        '/data/groups/$groupId/members/$userId/make-admin',
        body: {},
      );

      if (response['status'] == 'success') {

        return true;
      }

      throw Exception(response['message'] ?? 'Failed to make admin');
    } catch (e) {

      rethrow;
    }
  }

  /// إزالة صلاحيات المشرف (تحويله إلى عضو عادي)
  Future<bool> removeAdmin(int groupId, int userId) async {
    try {

      // TODO: Update endpoint when backend is ready
      final response = await _apiClient.post(
        '/data/groups/$groupId/members/$userId/remove-admin',
        body: {},
      );

      if (response['status'] == 'success') {

        return true;
      }

      throw Exception(response['message'] ?? 'Failed to remove admin');
    } catch (e) {

      rethrow;
    }
  }

  /// جلب قائمة الأصدقاء المتاحين للدعوة إلى المجموعة
  Future<List<Map<String, dynamic>>> getFriendsToInvite(int groupId) async {
    try {

      final response = await _apiClient.get(
        '/data/groups/$groupId/invitable-friends',
      );

      if (response['status'] == 'success') {
        final data = response['data'];
        if (data != null && data['friends'] != null) {
          final friends = (data['friends'] as List)
              .map((friend) => friend as Map<String, dynamic>)
              .toList();

          return friends;
        }
      }

      return [];
    } catch (e) {

      rethrow;
    }
  }

  /// إرسال دعوة لصديق واحد للانضمام إلى المجموعة
  Future<bool> inviteFriend(int groupId, int userId) async {
    try {

      final response = await _apiClient.post(
        '/data/groups/$groupId/invite/$userId',
        body: {},
      );

      if (response['status'] == 'success') {

        return true;
      }

      throw Exception(response['message'] ?? 'Failed to send invitation');
    } catch (e) {

      rethrow;
    }
  }

  /// إرسال دعوات لعدة أصدقاء (يرسل دعوة منفصلة لكل صديق)
  Future<Map<String, dynamic>> inviteFriends(int groupId, List<int> userIds) async {
    int successCount = 0;
    int failedCount = 0;
    List<int> failedUsers = [];

    for (final userId in userIds) {
      try {
        await inviteFriend(groupId, userId);
        successCount++;
      } catch (e) {
        failedCount++;
        failedUsers.add(userId);

      }
    }

    return {
      'success_count': successCount,
      'failed_count': failedCount,
      'failed_users': failedUsers,
    };
  }
}

