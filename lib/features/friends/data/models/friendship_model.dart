enum FriendshipStatus {
  none,           // لا توجد علاقة صداقة
  pending,        // طلب صداقة مرسل (بانتظار الرد)
  requested,      // طلب صداقة مستلم (بحاجة لقبول أو رفض)
  friends,        // أصدقاء
  following,      // متابعة فقط
  blocked,        // محظور
}

class FriendshipInfo {
  final int userId;
  final FriendshipStatus status;
  final bool canSendRequest;
  final bool canFollow;
  final String displayName;
  final String avatarUrl;

  const FriendshipInfo({
    required this.userId,
    required this.status,
    this.canSendRequest = true,
    this.canFollow = true,
    required this.displayName,
    this.avatarUrl = '',
  });

  factory FriendshipInfo.fromJson(Map<String, dynamic> json) {
    return FriendshipInfo(
      userId: json['user_id'] ?? 0,
      status: _statusFromString(json['friendship_status'] ?? 'none'),
      canSendRequest: json['can_send_request'] ?? true,
      canFollow: json['can_follow'] ?? true,
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }

  static FriendshipStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'friends':
        return FriendshipStatus.friends;
      case 'pending':
        return FriendshipStatus.pending;
      case 'requested':
        return FriendshipStatus.requested;
      case 'following':
        return FriendshipStatus.following;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.none;
    }
  }

  FriendshipInfo copyWith({
    int? userId,
    FriendshipStatus? status,
    bool? canSendRequest,
    bool? canFollow,
    String? displayName,
    String? avatarUrl,
  }) {
    return FriendshipInfo(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      canSendRequest: canSendRequest ?? this.canSendRequest,
      canFollow: canFollow ?? this.canFollow,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class FriendActionResult {
  final bool success;
  final String message;
  final FriendshipStatus newStatus;
  final Map<String, dynamic>? data;

  const FriendActionResult({
    required this.success,
    required this.message,
    required this.newStatus,
    this.data,
  });

  factory FriendActionResult.success(String message, FriendshipStatus newStatus) {
    return FriendActionResult(
      success: true,
      message: message,
      newStatus: newStatus,
    );
  }

  factory FriendActionResult.error(String message, FriendshipStatus currentStatus) {
    return FriendActionResult(
      success: false,
      message: message,
      newStatus: currentStatus,
    );
  }
}