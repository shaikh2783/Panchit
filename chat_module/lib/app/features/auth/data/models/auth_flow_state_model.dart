class AuthFlowStateModel {
  const AuthFlowStateModel({
    required this.nextStep,
    required this.activationType,
    required this.email,
    required this.userName,
    required this.userPicture,
    required this.message,
    required this.isBanned,
    required this.bannedMessage,
    required this.isActivated,
    required this.isApproved,
    required this.isStarted,
    required this.activationRequired,
    required this.approvalRequired,
    required this.gettingStartedRequired,
  });

  final String nextStep;
  final String activationType;
  final String email;
  final String userName;
  final String userPicture;
  final String message;
  final bool isBanned;
  final String bannedMessage;
  final bool isActivated;
  final bool isApproved;
  final bool isStarted;
  final bool activationRequired;
  final bool approvalRequired;
  final bool gettingStartedRequired;

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
      resolvedNextStep == 'home' && isActivated && isApproved && isStarted;

  factory AuthFlowStateModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackNextStep,
    String? fallbackEmail,
  }) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final authState =
        (data['auth_state'] as Map<String, dynamic>?) ??
        (data['state'] as Map<String, dynamic>?) ??
        data;
    final user = (data['user'] as Map<String, dynamic>?) ?? const {};

    return AuthFlowStateModel(
      nextStep:
          data['next_step']?.toString() ??
          authState['next_step']?.toString() ??
          fallbackNextStep ??
          '',
      activationType:
          data['activation_type']?.toString() ??
          authState['activation_type']?.toString() ??
          '',
      email:
          data['user_email']?.toString() ??
          user['user_email']?.toString() ??
          fallbackEmail ??
          '',
      userName:
          data['user_fullname']?.toString() ??
          user['user_fullname']?.toString() ??
          '${user['user_firstname']?.toString() ?? ''} ${user['user_lastname']?.toString() ?? ''}'
              .trim(),
      userPicture:
          data['user_picture']?.toString() ??
          user['user_picture']?.toString() ??
          '',
      message: json['message']?.toString() ?? data['message']?.toString() ?? '',
      isBanned: _parseBool(user['user_banned'] ?? data['user_banned']),
      bannedMessage:
          user['user_banned_message']?.toString().trim() ??
          data['user_banned_message']?.toString().trim() ??
          json['message']?.toString().trim() ??
          '',
      isActivated: _parseBool(authState['activated'] ?? data['user_activated']),
      isApproved: _parseBool(authState['approved'] ?? data['user_approved']),
      isStarted: _parseBool(authState['started'] ?? data['user_started']),
      activationRequired: _parseBool(
        authState['activation_required'] ?? data['activation_required'],
      ),
      approvalRequired: _parseBool(
        authState['approval_required'] ?? data['approval_required'],
      ),
      gettingStartedRequired: _parseBool(
        authState['getting_started_required'] ??
            data['getting_started_required'],
      ),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
}
