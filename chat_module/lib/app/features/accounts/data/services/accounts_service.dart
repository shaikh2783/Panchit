import 'dart:io';

import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_endpoints.dart';
import '../models/connected_accounts_models.dart';

class AccountsService {
  AccountsService(this._apiClient);

  final ChatModuleApiClient _apiClient;

  Future<ConnectedAccountsResponse> fetchConnectedAccounts() async {
    final response = await _apiClient.get(
      ApiEndpoints.connectedAccounts,
      authenticated: true,
    );
    return ConnectedAccountsResponse.fromJson(response);
  }

  Future<ConnectedAccountsResponse> addConnectedAccount({
    required String usernameEmail,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.connectedAccountsAdd,
      authenticated: true,
      body: <String, dynamic>{
        'username_email': usernameEmail.trim(),
        'password': password,
      },
    );
    return ConnectedAccountsResponse.fromJson(response);
  }

  Future<SwitchConnectedAccountResult> switchConnectedAccount({
    required int userId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.connectedAccountsSwitch,
      authenticated: true,
      body: <String, dynamic>{
        'user_id': userId,
        'device_type': _resolveDeviceType(),
        'device_name': 'Messenger App',
        'device_os_version': Platform.operatingSystemVersion,
      },
    );
    return SwitchConnectedAccountResult.fromJson(response);
  }

  Future<ConnectedAccountsResponse> removeConnectedAccount({
    required int userId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.connectedAccountsRemove,
      authenticated: true,
      body: <String, dynamic>{'user_id': userId},
    );
    final data = (response['data'] as Map<String, dynamic>?) ?? const {};
    final accounts = (data['accounts'] as Map<String, dynamic>?) ?? const {};
    return ConnectedAccountsResponse.fromJson({'data': accounts});
  }

  Future<ConnectedAccountsResponse> revokeConnectedAccount() async {
    final response = await _apiClient.post(
      ApiEndpoints.connectedAccountsRevoke,
      authenticated: true,
    );
    final data = (response['data'] as Map<String, dynamic>?) ?? const {};
    final accounts = (data['accounts'] as Map<String, dynamic>?) ?? const {};
    return ConnectedAccountsResponse.fromJson({'data': accounts});
  }

  String _resolveDeviceType() {
    if (Platform.isAndroid) {
      return 'A';
    }
    if (Platform.isIOS) {
      return 'I';
    }
    return 'W';
  }
}
