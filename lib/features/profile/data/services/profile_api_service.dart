import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/user_profile_model.dart';
import '../models/profile_completion_model.dart';
class ProfileApiService {
  final ApiClient _apiClient;
  ProfileApiService(this._apiClient);
  /// Get user profile by username
  Future<UserProfileResponse> getProfileByUsername(String username) async {
    try {
      final response = await _apiClient.get(
        configCfgP('user_profile'),
        queryParameters: {'username': username},
      );
      // Check if response is valid JSON structure
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid response format from server');
      }
      if (response['status'] != 'success') {
        final errorMsg = response['message']?.toString() ?? 'Failed to load profile';
        throw Exception(errorMsg);
      }
      if (response['data'] != null && response['data']['profile'] != null) {
      }
      return UserProfileResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  /// Get user profile by user ID
  Future<UserProfileResponse> getProfileById(int userId) async {
    try {
      final response = await _apiClient.get(
        configCfgP('user_general'),
        queryParameters: {'user_id': userId.toString()},
      );
      if (response['status'] == 'success') {
        return UserProfileResponse.fromJson(response);
      } else {
        throw Exception(response['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Get current user's own profile
  Future<UserProfileResponse> getMyProfile() async {
    try {
      // استخدام /data/user بدون أي parameters يعيد بيانات المستخدم الحالي
      final response = await _apiClient.get(configCfgP('user_general'));
      if (response['status'] == 'success') {
        return UserProfileResponse.fromJson(response);
      } else {
        throw Exception(response['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Get profile completion status
  Future<ProfileCompletionResponse> getProfileCompletion() async {
    try {
      final response = await _apiClient.get(configCfgP('profile_completion'));
      if (response['data'] != null) {
      }
      if (response['status'] == 'success') {
        return ProfileCompletionResponse.fromJson(response);
      } else {
        throw Exception(response['message'] ?? 'Failed to load profile completion');
      }
    } catch (e) {
      rethrow;
    }
  }
}
