import 'auth_user_model.dart';

class LoginResultModel {
  const LoginResultModel({
    required this.userId,
    required this.sessionToken,
    required this.user,
    required this.isBanned,
    required this.bannedMessage,
    required this.nextStep,
    required this.twoFactorEnabled,
    required this.twoFactorMethod,
    required this.isActivated,
    required this.isApproved,
    required this.isStarted,
    required this.activationRequired,
    required this.approvalRequired,
    required this.gettingStartedRequired,
  });

  final int userId;
  final String sessionToken;
  final AuthUserModel? user;
  final bool isBanned;
  final String bannedMessage;
  final String nextStep;
  final bool twoFactorEnabled;
  final String twoFactorMethod;
  final bool isActivated;
  final bool isApproved;
  final bool isStarted;
  final bool activationRequired;
  final bool approvalRequired;
  final bool gettingStartedRequired;

  bool get hasActiveSession => sessionToken.trim().isNotEmpty && userId != 0;

  String get resolvedNextStep {
    if (nextStep.trim().isNotEmpty) {
      return nextStep.trim().toLowerCase();
    }
    if (activationRequired || !isActivated) {
      return 'activation';
    }
    if (approvalRequired || !isApproved) {
      return 'approval';
    }
    if (gettingStartedRequired || !isStarted) {
      return 'getting_started';
    }
    return 'home';
  }

  bool get canEnterHome =>
      hasActiveSession &&
      resolvedNextStep == 'home' &&
      isActivated &&
      isApproved &&
      isStarted;

  factory LoginResultModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final session = (data['session'] as Map<String, dynamic>?) ?? const {};
    final userJson =
        (session['user'] as Map<String, dynamic>?) ??
        (data['user'] as Map<String, dynamic>?) ??
        <String, dynamic>{
          'user_id': data['user_id'],
          'user_fullname': data['user_fullname'],
          'user_email': data['user_email'],
          'user_picture': data['user_picture'],
          'user_firstname': data['user_firstname'],
          'user_lastname': data['user_lastname'],
          'user_activated': data['user_activated'],
          'user_approved': data['user_approved'],
          'user_started': data['user_started'],
        };
    final authState = (data['auth_state'] as Map<String, dynamic>?) ?? const {};

    return LoginResultModel(
      userId: _parseInt(data['user_id'] ?? userJson['user_id']),
      sessionToken:
          session['token']?.toString() ??
          data['session_token']?.toString() ??
          data['token']?.toString() ??
          '',
      user: _parseInt(userJson['user_id']) == 0
          ? null
          : AuthUserModel.fromJson(userJson),
      isBanned: _parseBool(userJson['user_banned']),
      bannedMessage:
          userJson['user_banned_message']?.toString().trim() ??
          json['message']?.toString().trim() ??
          '',
      nextStep:
          data['next_step']?.toString() ??
          authState['next_step']?.toString() ??
          '',
      twoFactorEnabled: _parseBool(data['2FA'] ?? data['two_factor']),
      twoFactorMethod: data['method']?.toString().trim() ?? '',
      isActivated: _parseBool(
        authState['activated'] ?? userJson['user_activated'],
      ),
      isApproved: _parseBool(
        authState['approved'] ?? userJson['user_approved'],
      ),
      isStarted: _parseBool(authState['started'] ?? userJson['user_started']),
      activationRequired: _parseBool(
        authState['activation_required'] ??
            (!_parseBool(userJson['user_activated'])),
      ),
      approvalRequired: _parseBool(
        authState['approval_required'] ??
            (!_parseBool(userJson['user_approved'])),
      ),
      gettingStartedRequired: _parseBool(
        authState['getting_started_required'] ??
            (!_parseBool(userJson['user_started'])),
      ),
    );
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
