import '../data/models/group.dart';
import '../data/models/group_exceptions.dart';
import '../data/datasources/groups_api_service.dart';
import '../data/datasources/groups_management_service.dart';
/// Repository for Groups feature
/// Updated to work with new API structure
class GroupsRepository {
  final GroupsApiService _apiService;
  final GroupsManagementService _managementService;
  GroupsRepository(this._apiService, this._managementService);
  /// Get group by ID
  Future<Group> getGroupById(int groupId) async {
    try {
      return await _apiService.getGroupById(groupId);
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Get group by name
  Future<Group> getGroupByName(String groupName) async {
    try {
      return await _apiService.getGroupByName(groupName);
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Get groups with pagination and filters
  Future<GroupsResponse> getGroups({
    int page = 1,
    int limit = 20,
    int? category,
    String? search,
    String? privacy,
  }) async {
    try {
      return await _apiService.getGroups(
        page: page,
        limit: limit,
        category: category,
        search: search,
        privacy: privacy,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Get joined groups (groups user is a member of)
  Future<GroupsResponse> getJoinedGroups({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      return await _apiService.getJoinedGroups(
        page: page,
        limit: limit,
        search: search,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Get my groups (groups owned/admin by user)
  Future<GroupsResponse> getMyGroups({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      return await _apiService.getMyGroups(
        page: page,
        limit: limit,
        search: search,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Join group
  Future<GroupJoinResult> joinGroup(int groupId) async {
    try {
      return await _managementService.joinGroup(groupId);
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Leave a group
  Future<bool> leaveGroup(int groupId) async {
    try {
      await _managementService.leaveGroup(groupId);
      return true; // Return success if no exception is thrown
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Get group members
  Future<GroupMembersResponse> getGroupMembers(
    int groupId, {
    int page = 1,
    int limit = 20,
    String status = 'approved',
  }) async {
    try {
      return await _apiService.getGroupMembers(
        groupId,
        page: page,
        limit: limit,
        status: status,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Approve membership request (admin only)
  Future<bool> approveMembershipRequest(int groupId, int userId) async {
    try {
      return await _managementService.approveMembershipRequest(groupId, userId);
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Reject membership request (admin only)
  Future<bool> rejectMembershipRequest(int groupId, int userId) async {
    try {
      return await _managementService.rejectMembershipRequest(groupId, userId);
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Remove member from group (admin only)
  Future<bool> removeMember(int groupId, int userId) async {
    try {
      return await _managementService.removeMember(
        groupId: groupId,
        userId: userId,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  // Legacy method names for backward compatibility with existing Bloc
  /// Accept member (legacy method name)
  Future<bool> acceptMember(int groupId, int userId) async {
    return await approveMembershipRequest(groupId, userId);
  }
  /// Reject member (legacy method name)
  Future<bool> rejectMember(int groupId, int userId) async {
    return await rejectMembershipRequest(groupId, userId);
  }
  /// Make member admin (placeholder - needs implementation)
  Future<bool> makeMemberAdmin(int groupId, int userId) async {
    // TODO: Implement this functionality in GroupsManagementService
    throw UnimplementedError('makeMemberAdmin functionality not yet implemented');
  }
  /// Remove admin role (placeholder - needs implementation)
  Future<bool> removeAdminRole(int groupId, int userId) async {
    // TODO: Implement this functionality in GroupsManagementService
    throw UnimplementedError('removeAdminRole functionality not yet implemented');
  }
  /// Get group categories
  Future<List<GroupCategory>> getGroupCategories() async {
    try {
      return await _apiService.getGroupCategories();
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Create new group
  Future<Map<String, dynamic>> createGroup({
    required String title,
    required String name,
    required String description,
    required String privacy,
    required int category,
    int? country,
    int? categoryId, // Backward compatibility
  }) async {
    try {
      return await _managementService.createGroup(
        title: title,
        name: name,
        description: description,
        privacy: privacy,
        category: category,
        country: country,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Update group
  Future<Map<String, dynamic>> updateGroup({
    required int groupId,
    String? title,
    String? description,
    String? privacy,
    int? category,
    int? categoryId, // Backward compatibility
  }) async {
    try {
      return await _managementService.updateGroup(
        groupId: groupId,
        title: title,
        description: description,
        privacy: privacy,
        category: categoryId ?? category,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Delete group (admin only)
  Future<bool> deleteGroup(int groupId) async {
    try {
      return await _managementService.deleteGroup(groupId);
    } catch (e) {
      throw _handleError(e);
    }
  }
  /// Handle errors and convert them to appropriate exceptions
  Exception _handleError(Object error) {
    if (error is GroupException) {
      return error;
    }
    return GroupException(
      code: 500,
      message: 'حدث خطأ غير متوقع',
    );
  }
}