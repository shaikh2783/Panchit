import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/session_model.dart';

class SessionsApiService {
  final ApiClient _apiClient;

  SessionsApiService(this._apiClient);

  /// جلب قائمة الجلسات النشطة
  Future<Map<String, dynamic>> getSessions() async {
    try {

      final response = await _apiClient.get(configCfgP('sessions'));

      if (response['status'] == 'success') {
        final data = response['data'];
        return {
          'success': true,
          'sessions': (data['sessions'] as List)
              .map((s) => UserSession.fromJson(s))
              .toList(),
          'totalSessions': data['total_sessions'],
          'currentSessionId': data['current_session_id'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch sessions',
        };
      }
    } catch (e) {

      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// حذف جلسة محددة
  Future<Map<String, dynamic>> deleteSession({required int sessionId}) async {
    try {

      final response = await _apiClient.post(
        configCfgP('sessions_delete'),
        body: {'session_id': sessionId},
      );

      if (response['status'] == 'success') {
        return {
          'success': true,
          'message': response['message'] ?? 'Session deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to delete session',
        };
      }
    } catch (e) {

      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// حذف جميع الجلسات الأخرى
  Future<Map<String, dynamic>> deleteAllOtherSessions() async {
    try {

      final response = await _apiClient.post(
        configCfgP('sessions_delete_all'),
        body: {},
      );

      if (response['status'] == 'success') {
        final data = response['data'];
        return {
          'success': true,
          'message': response['message'] ?? 'All sessions deleted successfully',
          'deletedCount': data['deleted_count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to delete sessions',
        };
      }
    } catch (e) {

      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
