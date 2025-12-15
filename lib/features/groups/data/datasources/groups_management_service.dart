import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/group_exceptions.dart';
/// Groups Management Service for creating, updating, deleting, and managing memberships
/// Based on GROUPS_MANAGEMENT_API.md documentation
class GroupsManagementService {
  final ApiClient _apiClient;
  GroupsManagementService(this._apiClient);
  /// Create a new group
  /// Endpoint: POST /data/group/create
  Future<Map<String, dynamic>> createGroup({
    required String title,
    required String name,
    required String description,
    required String privacy,
    required int category,
    int? country,
  }) async {
    try {
      if (kDebugMode) {
      }
      final response = await _apiClient.post(
        configCfgP('group_create'),
        data: {
          'title': title,
          'name': name,
          'description': description,
          'privacy': privacy,
          'category': category,
          'group_country': (country ?? 1).toString(), // Convert to string
        },
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
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
  /// Update group information (admin only)
  /// Endpoint: PUT /data/group/update?group_id=123 
  /// NOTE: Using POST since some ApiClient implementations don't support PUT
  /// Backend should handle both POST and PUT methods for this endpoint
  Future<Map<String, dynamic>> updateGroup({
    required int groupId,
    String? title,
    String? description,
    String? privacy,
    int? category,
  }) async {
    try {
      if (kDebugMode) {
      }
      final Map<String, dynamic> body = {
        'group_id': groupId, // Include in body for compatibility
      };
      if (title != null) body['group_title'] = title;
      if (description != null) body['group_description'] = description;
      if (privacy != null) body['group_privacy'] = privacy;
      if (category != null) body['group_category'] = category;
      final response = await _apiClient.post(
        '${configCfgP('groups_list')}/$groupId',
        data: body,
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
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
  /// Delete a group (admin only)
  /// Endpoint: DELETE /data/group/delete?group_id=123 
  /// NOTE: Using POST since some ApiClient implementations don't support DELETE
  /// Backend should handle both POST and DELETE methods for this endpoint
  Future<bool> deleteGroup(int groupId) async {
    try {
      if (kDebugMode) {
      }
      final response = await _apiClient.post(
        configCfgP('group_delete'),
        data: {
          'group_id': groupId,
        },
      );
      return response['status'] == 'success';
    } catch (e) {
      if (kDebugMode) {
      }
      return false;
    }
  }
  /// Join a group or request membership
  /// Endpoint: POST /data/group/join?group_id=123
  Future<GroupJoinResult> joinGroup(int groupId) async {
    try {
      if (kDebugMode) {
      }
      final response = await _apiClient.post(
        '${configCfgP('groups_list')}/$groupId/join',
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return GroupJoinResult.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw GroupException(
          code: 400,
          message: response['message'] ?? 'Failed to join group',
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  /// Leave a group
  /// Endpoint: POST /data/group/leave?group_id=123
  Future<bool> leaveGroup(int groupId) async {
    try {
      if (kDebugMode) {
      }
      final response = await _apiClient.post(
        '${configCfgP('groups_list')}/$groupId/leave',
      );
      return response['status'] == 'success';
    } catch (e) {
      if (kDebugMode) {
      }
      return false;
    }
  }
  /// Manage membership request - approve or reject (admin only)
  /// Endpoint: POST /data/group/membership?group_id=123&user_id=456&action=approve
  Future<bool> manageMembershipRequest({
    required int groupId,
    required int userId,
    required String action, // 'approve' or 'reject'
  }) async {
    try {
      if (kDebugMode) {
      }
      final response = await _apiClient.post(
        '${configCfgP('groups_list')}/$groupId/member/$userId/action/$action',
      );
      return response['status'] == 'success';
    } catch (e) {
      if (kDebugMode) {
      }
      return false;
    }
  }
  /// Approve membership request (admin only)
  Future<bool> approveMembershipRequest(int groupId, int userId) async {
    return await manageMembershipRequest(
      groupId: groupId,
      userId: userId,
      action: 'approve',
    );
  }
  /// Reject membership request (admin only)
  Future<bool> rejectMembershipRequest(int groupId, int userId) async {
    return await manageMembershipRequest(
      groupId: groupId,
      userId: userId,
      action: 'reject',
    );
  }
  /// Remove a member from group (admin only)
  /// Endpoint: DELETE /data/group/member?group_id=123&user_id=456 (using POST since ApiClient doesn't have DELETE)
  Future<bool> removeMember({
    required int groupId,
    required int userId,
  }) async {
    try {
      if (kDebugMode) {
      }
      final response = await _apiClient.post(
        '${configCfgP('groups_list')}/$groupId/member/$userId/remove',
      );
      return response['status'] == 'success';
    } catch (e) {
      if (kDebugMode) {
      }
      return false;
    }
  }
}
