class UserSession {
  final int sessionId;
  final String sessionToken;
  final String sessionDate;
  final String sessionType; // W, A, I
  final String userIp;
  final String? userBrowser;
  final String userOs;
  final String? userOsVersion;
  final String? userDeviceName;
  final bool isCurrent;

  UserSession({
    required this.sessionId,
    required this.sessionToken,
    required this.sessionDate,
    required this.sessionType,
    required this.userIp,
    this.userBrowser,
    required this.userOs,
    this.userOsVersion,
    this.userDeviceName,
    required this.isCurrent,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      sessionId: json['session_id'] ?? 0,
      sessionToken: json['session_token'] ?? '',
      sessionDate: json['session_date'] ?? '',
      sessionType: json['session_type'] ?? 'W',
      userIp: json['user_ip'] ?? '',
      userBrowser: json['user_browser'],
      userOs: json['user_os'] ?? '',
      userOsVersion: json['user_os_version'],
      userDeviceName: json['user_device_name'],
      isCurrent: json['is_current'] ?? false,
    );
  }

  String get deviceTypeLabel {
    switch (sessionType) {
      case 'W':
        return 'Web';
      case 'A':
        return 'Android';
      case 'I':
        return 'iOS';
      default:
        return 'Unknown';
    }
  }

  String get deviceLabel {
    if (userDeviceName != null && userDeviceName!.isNotEmpty) {
      return userDeviceName!;
    }
    if (userBrowser != null && userBrowser!.isNotEmpty) {
      return '$userBrowser on $userOs';
    }
    final osVersion = userOsVersion?.isNotEmpty == true
        ? ' $userOsVersion'
        : '';
    return '$userOs$osVersion';
  }
}
