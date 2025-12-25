import '../../../feed/data/models/posts_response.dart';
import '../models/group.dart';
import '../models/group_privacy.dart';
import '../models/groups_response.dart';
import '../services/groups_api_service.dart';

/// Repository للمجموعات - يدير المنطق التجاري وإدارة الحالة
class GroupsRepository {
  final GroupsApiService _apiService;

  GroupsRepository(this._apiService);

  /// جلب جميع البيانات مرة واحدة (المحسّن)
  Future<GroupsOverviewResponse> getAllTabs() async {
    return await _apiService.getAllTabs();
  }

  /// جلب المجموعات المنضم إليها
  Future<List<Group>> getJoinedGroups({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.getJoinedGroups(
        page: page,
        limit: limit,
      );
      return response.groups;
    } catch (e) {
      return [];
    }
  }

  /// جلب المجموعات المُدارة
  Future<List<Group>> getManagedGroups({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.getManagedGroups(
        page: page,
        limit: limit,
      );
      return response.groups;
    } catch (e) {
      return [];
    }
  }

  /// جلب المجموعات المقترحة
  Future<List<Group>> getSuggestedGroups({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.getSuggestedGroups(
        page: page,
        limit: limit,
      );
      // فلترة المجموعات السرية (حل مؤقت حتى يتم إصلاح الباك إند)
      final filteredGroups = response.groups
          .where((group) => group.groupPrivacy != GroupPrivacy.secret)
          .toList();
      return filteredGroups;
    } catch (e) {
      return [];
    }
  }

  /// البحث في المجموعات
  Future<List<Group>> searchGroups({
    required String query,
    int? categoryId,
    String? privacy,
    int page = 1,
  }) async {
    try {
      final response = await _apiService.searchGroups(
        query: query,
        categoryId: categoryId,
        privacy: privacy,
        page: page,
      );
      // فلترة المجموعات السرية من نتائج البحث (حل مئقت)
      final filteredGroups = response.groups
          .where((group) => group.groupPrivacy != GroupPrivacy.secret)
          .toList();
      return filteredGroups;
    } catch (e) {
      return [];
    }
  }

  /// جلب تفاصيل مجموعة
  Future<Group?> getGroupDetails(int groupId) async {
    return await _apiService.getGroupDetails(groupId);
  }

  /// الانضمام لمجموعة
  Future<bool> joinGroup(int groupId) async {
    return await _apiService.joinGroup(groupId);
  }

  /// مغادرة مجموعة
  Future<bool> leaveGroup(int groupId) async {
    return await _apiService.leaveGroup(groupId);
  }

  /// إنشاء مجموعة جديدة
  Future<Map<String, dynamic>?> createGroup({
    required String title,
    required String username,
    required String privacy,
    required int categoryId,
    String? description,
    int? countryId,
    int? languageId,
  }) async {
    return await _apiService.createGroup(
      title: title,
      username: username,
      privacy: privacy,
      categoryId: categoryId,
      description: description,
      countryId: countryId,
      languageId: languageId,
    );
  }

  /// تحديث مجموعة
  Future<bool> updateGroup({
    required int groupId,
    String? title,
    String? username,
    String? description,
    String? privacy,
    int? categoryId,
  }) async {
    return await _apiService.updateGroup(
      groupId: groupId,
      title: title,
      username: username,
      description: description,
      privacy: privacy,
      categoryId: categoryId,
    );
  }

  /// حذف مجموعة
  Future<bool> deleteGroup(int groupId) async {
    return await _apiService.deleteGroup(groupId);
  }

  /// جلب منشورات مجموعة
  Future<PostsResponse> fetchGroupPosts({
    required String groupId,
    int limit = 10,
    int offset = 0,
  }) {
    return _apiService.fetchGroupPosts(
      groupId: int.parse(groupId),
      limit: limit,
      offset: offset,
    );
  }
}
