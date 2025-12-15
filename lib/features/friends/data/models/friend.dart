class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderUsername,
    required this.senderAvatar,
    required this.sentAt,
    required this.mutualFriendsCount,
    this.isVerified = false,
    this.bio = '',
    this.location = '',
    this.status = FriendRequestStatus.pending,
  });
  final int id;
  final int senderId;
  final String senderName;
  final String senderUsername;
  final String senderAvatar;
  final DateTime sentAt;
  final int mutualFriendsCount;
  final bool isVerified;
  final String bio;
  final String location;
  final FriendRequestStatus status;
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(sentAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
  String get mutualFriendsText {
    if (mutualFriendsCount == 0) return 'No mutual friends';
    if (mutualFriendsCount == 1) return '1 mutual friend';
    return '$mutualFriendsCount mutual friends';
  }
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      senderUsername: json['sender_username'] ?? '',
      senderAvatar: json['sender_avatar'] ?? '',
      sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
      mutualFriendsCount: json['mutual_friends_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      bio: json['bio'] ?? '',
      location: json['location'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_username': senderUsername,
      'sender_avatar': senderAvatar,
      'sent_at': sentAt.toIso8601String(),
      'mutual_friends_count': mutualFriendsCount,
      'is_verified': isVerified,
      'bio': bio,
      'location': location,
      'status': status.name,
    };
  }
}
enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
}