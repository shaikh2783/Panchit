import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_endpoints.dart';
import '../../../../core/localization/app_translations.dart';
import 'package:get/get.dart';
import '../models/blocked_users_models.dart';

class BlockedUsersService {
  BlockedUsersService(this._apiClient);

  final ChatModuleApiClient _apiClient;

  Future<BlockedUsersResponse> fetchBlockedUsers({int offset = 0}) async {
    final response = await _apiClient.get(
      ApiEndpoints.userBlockedList,
      authenticated: true,
      queryParameters: <String, dynamic>{'offset': offset},
    );
    return BlockedUsersResponse.fromJson(response);
  }

  Future<String> blockUser({required int userId}) async {
    final response = await _apiClient.post(
      ApiEndpoints.userBlock,
      authenticated: true,
      body: <String, dynamic>{'user_id': userId, 'target_user_id': userId},
    );
    return _resolveMessage(
      response,
      fallback: AppTranslations.chatUserBlocked.tr,
    );
  }

  Future<String> unblockUser({required int userId}) async {
    final response = await _apiClient.post(
      ApiEndpoints.userUnblock,
      authenticated: true,
      body: <String, dynamic>{'user_id': userId, 'target_user_id': userId},
    );
    return _resolveMessage(
      response,
      fallback: AppTranslations.blockedUsersUserUnblocked.tr,
    );
  }

  String _resolveMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final message = response['message']?.toString().trim() ?? '';
    return message.isEmpty ? fallback : message;
  }
}
