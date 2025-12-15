import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/group.dart';
import '../models/group_exceptions.dart';
/// Groups API Service implementation
/// Updated to match the new API documentation
class GroupsApiService {
  final ApiClient _apiClient;
  GroupsApiService(this._apiClient);
  /// Get group information by ID
  /// Endpoint: GET /data/group?group_id=123
  Future<Group> getGroupById(int groupId) async {
    try {
      if (kDebugMode) {
      }
      final response = await _apiClient.get(
        configCfgP('group_detail'),
        queryParameters: {
          'group_id': groupId.toString(),
        },
      );
      if (response['status'] == 'success' && response['data'] != null) {
        final group = Group.fromJson(response['data'] as Map<String, dynamic>);
        if (kDebugMode) {
        }
        return group;
      } else {
        throw GroupException(
          code: 400,
          message: response['message'] ?? 'Failed to get group information',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  /// Get group by name
  /// Endpoint: GET /data/group?group_name=asdasdasdasd
  Future<Group> getGroupByName(String groupName) async {
    try {
      if (kDebugMode) {
      }
      final response = await _apiClient.get(
        configCfgP('group_detail'),
        queryParameters: {
          'group_name': groupName,
        },
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return Group.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw GroupException(
          code: 400,
          message: response['message'] ?? 'Group not found',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  /// Get groups list with filters and pagination
  /// Endpoint: GET /data/groups?page=1&limit=20&category=1&search=test&privacy=public
  Future<GroupsResponse> getGroups({
    int page = 1,
    int limit = 20,
    int? category,
    String? search,
    String? privacy,
  }) async {
    try {
      if (kDebugMode) {
      }
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (category != null) queryParams['category'] = category.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (privacy != null && privacy.isNotEmpty) queryParams['privacy'] = privacy;
      final response = await _apiClient.get(
        configCfgP('groups_list'),
        queryParameters: queryParams,
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return GroupsResponse.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw GroupException(
          code: 400,
          message: response['message'] ?? 'Failed to get groups',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  /// Get user's owned groups (created by user)
  /// Endpoint: GET /data/user/groups/admin (updated endpoint)
  Future<GroupsResponse> getMyGroups({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      if (kDebugMode) {
      }
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': ((page - 1) * limit).toString(),
      };
      if (search?.isNotEmpty == true) {
        queryParams['q'] = search!;
      }
      final response = await _apiClient.get(
        configCfgP('user_groups_admin'),
        queryParameters: queryParams,
      );
      if (response['status'] == 'success') {
        if (kDebugMode) {
        }
        final groups = (response['data']['groups'] as List?)
            ?.map((json) {
              try {
                if (kDebugMode) {
                }
                final group = Group.fromJson(json as Map<String, dynamic>);
                if (kDebugMode) {
                }
                return group;
              } catch (e) {
                if (kDebugMode) {
                }
                return null;
              }
            })
            .where((group) => group != null)
            .cast<Group>()
            .toList() ?? [];
        final total = response['data']['total'] as int? ?? 0;
        final hasMore = groups.length >= limit;
        final pagination = Pagination(
          page: page,
          limit: limit,
          total: total,
          hasMore: hasMore,
          pages: (total / limit).ceil(),
        );
        return GroupsResponse(
          groups: groups, 
          pagination: pagination,
          filters: {},
        );
      } else {
        throw GroupException(
          code: response['status_code'] ?? 400,
          message: response['message'] ?? 'فشل في جلب مجموعاتي',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  /// Get group members with pagination and status filtering
  /// Endpoint: GET /data/group/members?group_id=123&page=1&limit=20&status=approved
  /// Note: Backend has SQL syntax issue with pagination, using workaround
  Future<GroupMembersResponse> getGroupMembers(
    int groupId, {
    int page = 1,
    int limit = 20,
    String status = 'approved',
  }) async {
    try {
      if (kDebugMode) {
      }
      // Temporary workaround: Try without pagination first due to backend SQL bug
      Map<String, String> queryParams = {
        'group_id': groupId.toString(),
        'status': status,
      };
      // Only add pagination if not first page to avoid backend SQL error
      if (page > 1 || limit != 20) {
        queryParams.addAll({
          'page': page.toString(),
          'limit': limit.toString(),
        });
      }
      final response = await _apiClient.get(
        configCfgP('group_members'),
        queryParameters: queryParams,
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return GroupMembersResponse.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw GroupException(
          code: 400,
          message: response['message'] ?? 'Failed to get group members',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      // إذا فشلت المقاطعة، جرب بدون معاملات المقاطعة
      if (page > 1 || limit != 20) {
        if (kDebugMode) {
        }
        return getGroupMembers(groupId, status: status);
      }
      rethrow;
    }
  }
  /// Get group categories (public endpoint - no auth required)
  /// Endpoint: GET /data/groups/categories
  Future<List<GroupCategory>> getGroupCategories() async {
    try {
      if (kDebugMode) {
      }
      final response = await _apiClient.get(configCfgP('groups_categories'));
      if (response['status'] == 'success' && response['data'] != null) {
        final categoriesData = response['data']['categories'] as List<dynamic>;
        return categoriesData.map((json) => GroupCategory.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw GroupException(
          code: 400,
          message: response['message'] ?? 'Failed to get group categories',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  /// Create new group
  /// Endpoint: POST /data/group/create (moved to GroupsManagementService)
  @Deprecated('Use GroupsManagementService.createGroup instead')
  Future<Group> createGroup(Map<String, dynamic> groupData) async {
    try {
      final response = await _apiClient.post(
        configCfgP('group_create'),
        data: groupData,
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return Group.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw GroupException(
          code: 400,
          message: response['message'] ?? 'Failed to create group',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  /// Update group
  /// Endpoint: PUT /data/group/update (moved to GroupsManagementService)
  @Deprecated('Use GroupsManagementService.updateGroup instead')
  Future<Group> updateGroup(int groupId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.post(
        '${configCfgP('groups_list')}/$groupId',
        data: updates,
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return Group.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw GroupException(
          code: 400,
          message: response['message'] ?? 'Failed to update group',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  /// Delete group
  /// Endpoint: DELETE /data/group/delete (moved to GroupsManagementService)
  @Deprecated('Use GroupsManagementService.deleteGroup instead')
  Future<bool> deleteGroup(int groupId) async {
    try {
      final response = await _apiClient.post(
        '${configCfgP('groups_list')}/$groupId/delete',
      );
      return response['status'] == 'success';
    } catch (e) {
      if (kDebugMode) {
      }
      return false;
    }
  }
  /// Get joined groups (groups user is a member of)
  /// Endpoint: GET /data/user/groups
  Future<GroupsResponse> getJoinedGroups({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      if (kDebugMode) {
      }
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': ((page - 1) * limit).toString(),
      };
      if (search?.isNotEmpty == true) {
        queryParams['q'] = search!;
      }
      final response = await _apiClient.get(
        configCfgP('user_groups'),
        queryParameters: queryParams,
      );
      if (response['status'] == 'success') {
        if (kDebugMode) {
        }
        final groups = (response['data']['groups'] as List?)
            ?.map((json) {
              try {
                if (kDebugMode) {
                }
                return Group.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                if (kDebugMode) {
                }
                return null;
              }
            })
            .where((group) => group != null)
            .cast<Group>()
            .toList() ?? [];
        final total = response['data']['total'] as int? ?? 0;
        final hasMore = groups.length >= limit;
        final pagination = Pagination(
          page: page,
          limit: limit,
          total: total,
          hasMore: hasMore,
          pages: (total / limit).ceil(),
        );
        return GroupsResponse(
          groups: groups, 
          pagination: pagination,
          filters: {},
        );
      } else {
        throw GroupException(
          code: response['status_code'] ?? 400,
          message: response['message'] ?? 'فشل في جلب المجموعات المنضمة',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  }
