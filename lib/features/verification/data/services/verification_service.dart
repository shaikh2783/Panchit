import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/main.dart' show configCfgP;

class VerificationService {
  final ApiClient _apiClient;
  VerificationService(this._apiClient);

  /// Send account/page verification request
  Future<Map<String, dynamic>> requestVerification({
    String nodeType = 'user',
    int? nodeId, // required if nodeType == 'page'
    String? photo,
    String? passport,
    required String message,
    String? businessWebsite,
    String? businessAddress,
  }) async {
    // Allow override via dynamic config when available
    final endpointOverride = configCfgP('verification_request');
    final path = (endpointOverride.isNotEmpty)
        ? endpointOverride
        : '/data/verification/request';

    final body = <String, dynamic>{
      'node_type': nodeType,
      if (nodeType == 'page' && nodeId != null) 'node_id': nodeId,
      if (photo != null) 'photo': photo,
      if (passport != null) 'passport': passport,
      'message': message,
      if (nodeType == 'page' && businessWebsite != null)
        'business_website': businessWebsite,
      if (nodeType == 'page' && businessAddress != null)
        'business_address': businessAddress,
    };

    final response = await _apiClient.post(path, body: body);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to submit verification request');
    }
    return response;
  }

  /// Get current verification status for account/page
  Future<Map<String, dynamic>> getStatus({
    String nodeType = 'user',
    int? nodeId,
  }) async {
    final endpointOverride = configCfgP('verification_status');
    final path = (endpointOverride.isNotEmpty)
        ? endpointOverride
        : '/data/verification/status';

    final response = await _apiClient.get(
      path,
      queryParameters: <String, String>{
        if (nodeType.isNotEmpty && nodeType != 'user') 'node_type': nodeType,
        if (nodeType == 'page' && nodeId != null) 'node_id': nodeId.toString(),
      },
    );
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to retrieve verification status');
    }
    return response;
  }
}
