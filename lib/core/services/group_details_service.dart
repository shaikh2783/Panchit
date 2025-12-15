import '../../core/network/api_client.dart';
import '../../main.dart' show configCfgP;
import '../../features/groups/data/models/group.dart';
/// خدمة جلب تفاصيل المجموعة من API
class GroupDetailsService {
  final ApiClient _apiClient;
  GroupDetailsService(this._apiClient);
  /// جلب تفاصيل المجموعة بالـ ID
  Future<Group?> getGroupDetails(String groupId) async {
    try {
      final response = await _apiClient.get(
        configCfgP('group_detail'),
        queryParameters: {'group_id': groupId},
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return Group.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
