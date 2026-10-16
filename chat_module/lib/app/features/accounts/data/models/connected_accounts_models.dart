import '../../../auth/data/models/auth_flow_state_model.dart';
import '../../../auth/data/models/auth_user_model.dart';

class ConnectedAccountsResponse {
  const ConnectedAccountsResponse({
    required this.switchAccountsEnabled,
    required this.currentUserId,
    required this.masterUserId,
    required this.isMasterAccount,
    required this.canAddAccount,
    required this.accounts,
  });

  final bool switchAccountsEnabled;
  final int currentUserId;
  final int masterUserId;
  final bool isMasterAccount;
  final bool canAddAccount;
  final List<ConnectedAccountModel> accounts;

  factory ConnectedAccountsResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};
    final items = _normalizeItems(data['items'])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(ConnectedAccountModel.fromJson)
        .toList();

    return ConnectedAccountsResponse(
      switchAccountsEnabled: _parseBool(data['switch_accounts_enabled']),
      currentUserId: _parseInt(data['current_user_id']),
      masterUserId: _parseInt(data['master_user_id']),
      isMasterAccount: _parseBool(data['is_master_account']),
      canAddAccount: _parseBool(data['can_add_account']),
      accounts: items,
    );
  }

  static List<dynamic> _normalizeItems(dynamic value) {
    if (value is List) {
      return value;
    }
    if (value is Map) {
      final map = Map<dynamic, dynamic>.from(value);
      if (map.containsKey('user_id')) {
        return <dynamic>[map];
      }
      return map.values.toList(growable: false);
    }
    return const <dynamic>[];
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
}

class ConnectedAccountModel {
  const ConnectedAccountModel({
    required this.userId,
    required this.userName,
    required this.displayName,
    required this.userPicture,
    required this.isCurrent,
    required this.isMaster,
    required this.switchable,
    required this.removable,
    required this.revokeAvailable,
    required this.url,
  });

  final int userId;
  final String userName;
  final String displayName;
  final String userPicture;
  final bool isCurrent;
  final bool isMaster;
  final bool switchable;
  final bool removable;
  final bool revokeAvailable;
  final String url;

  factory ConnectedAccountModel.fromJson(Map<String, dynamic> json) {
    return ConnectedAccountModel(
      userId: ConnectedAccountsResponse._parseInt(json['user_id']),
      userName: json['user_name']?.toString().trim() ?? '',
      displayName: json['display_name']?.toString().trim() ?? '',
      userPicture: json['user_picture']?.toString().trim() ?? '',
      isCurrent: ConnectedAccountsResponse._parseBool(json['is_current']),
      isMaster: ConnectedAccountsResponse._parseBool(json['is_master']),
      switchable: ConnectedAccountsResponse._parseBool(json['switchable']),
      removable: ConnectedAccountsResponse._parseBool(json['removable']),
      revokeAvailable: ConnectedAccountsResponse._parseBool(
        json['revoke_available'],
      ),
      url: json['url']?.toString().trim() ?? '',
    );
  }

  String get resolvedName {
    if (displayName.isNotEmpty) {
      return displayName;
    }
    if (userName.isNotEmpty) {
      return userName;
    }
    return 'Account';
  }
}

class SwitchConnectedAccountResult {
  const SwitchConnectedAccountResult({
    required this.switched,
    required this.accountId,
    required this.sessionToken,
    required this.user,
    required this.authState,
  });

  final bool switched;
  final int accountId;
  final String sessionToken;
  final AuthUserModel? user;
  final AuthFlowStateModel authState;

  factory SwitchConnectedAccountResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final session = (data['session'] as Map<String, dynamic>?) ?? const {};
    final userJson = (session['user'] as Map<String, dynamic>?) ?? const {};

    return SwitchConnectedAccountResult(
      switched: ConnectedAccountsResponse._parseBool(data['switched']),
      accountId: ConnectedAccountsResponse._parseInt(data['account_id']),
      sessionToken: session['token']?.toString().trim() ?? '',
      user: userJson.isEmpty ? null : AuthUserModel.fromJson(userJson),
      authState: AuthFlowStateModel.fromJson({
        'data': {
          'auth_state': session['auth_state'],
          'next_step': session['next_step'],
          'user': userJson,
        },
      }),
    );
  }
}
