import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/invitable_friend.dart';
import '../models/sent_invitation.dart';
import '../models/received_invitation.dart';
/// خدمة إدارة دعوات المجموعات
class GroupInvitationsService {
  final ApiClient _apiClient;
  GroupInvitationsService(this._apiClient);
  /// جلب الأصدقاء القابلين للدعوة إلى المجموعة
  Future<List<InvitableFriend>> getInvitableFriends({
    required int groupId,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('group_invites_friends'),
        queryParameters: {
          'group_id': groupId.toString(),
          'offset': offset.toString(),
        },
      );
      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> friendsJson = response['data'] is List 
            ? response['data'] 
            : [];
        final friends = friendsJson.map((json) => InvitableFriend.fromJson(json)).toList();
        return friends;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
  /// دعوة صديق إلى المجموعة
  Future<bool> inviteFriend({
    required int groupId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.post(
        configCfgP('group_invite'),
        body: {
          'group_id': groupId,
          'user_id': userId,
        },
      );
      if (response['status'] == 'success') {
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
  /// جلب الدعوات المرسلة من المستخدم للمجموعة
  Future<List<SentInvitation>> getSentInvitations({
    required int groupId,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('group_invites_sent'),
        queryParameters: {
          'group_id': groupId.toString(),
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );
      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> invitationsJson = response['data'] is List 
            ? response['data'] 
            : [];
        final invitations = invitationsJson.map((json) => SentInvitation.fromJson(json)).toList();
        return invitations;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
  /// إلغاء دعوة مرسلة
  Future<bool> cancelInvitation({
    required int groupId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.post(
        configCfgP('group_invite_cancel'),
        body: {
          'group_id': groupId,
          'user_id': userId,
        },
      );
      if (response['status'] == 'success') {
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
  /// جلب الدعوات المستلمة للمستخدم
  Future<List<ReceivedInvitation>> getReceivedInvitations({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('group_invites_received'),
        queryParameters: {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );
      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> invitationsJson = response['data'] is List 
            ? response['data'] 
            : [];
        final invitations = invitationsJson.map((json) => ReceivedInvitation.fromJson(json)).toList();
        return invitations;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
  /// قبول دعوة مجموعة
  Future<bool> acceptInvitation({
    required int groupId,
  }) async {
    try {
      final response = await _apiClient.post(
        configCfgP('group_invite_accept'),
        body: {
          'group_id': groupId,
        },
      );
      if (response['status'] == 'success') {
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
  /// رفض دعوة مجموعة
  Future<bool> declineInvitation({
    required int groupId,
  }) async {
    try {
      final response = await _apiClient.post(
        configCfgP('group_invite_decline'),
        body: {
          'group_id': groupId,
        },
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
