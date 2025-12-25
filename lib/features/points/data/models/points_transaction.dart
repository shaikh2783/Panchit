class PointsTransaction {
  final String id;
  final String userId;
  final String nodeId;
  final String nodeType;
  final double points;
  final String time;
  final Map<String, dynamic>? node;

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.nodeId,
    required this.nodeType,
    required this.points,
    required this.time,
    this.node,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['log_id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      nodeId: json['node_id'] ?? '',
      nodeType: json['node_type'] ?? '',
      points: double.tryParse(json['points'].toString()) ?? 0.0,
      time: json['time'] ?? '',
      node: json['node'] is Map<String, dynamic> ? json['node'] : null,
    );
  }

  String get typeLabel {
    switch (nodeType) {
      case 'post':
        return 'New Post';
      case 'post_view':
        return 'Post View';
      case 'post_comment':
        return 'Post Comment';
      case 'post_reaction':
        return 'Post Reaction';
      case 'comment':
        return 'Comment';
      case 'posts_reactions':
        return 'Post Reaction';
      case 'posts_photos_reactions':
        return 'Photo Reaction';
      case 'posts_comments_reactions':
        return 'Comment Reaction';
      case 'follow':
        return 'Follow';
      case 'referred':
        return 'Referral';
      default:
        return nodeType;
    }
  }

  String get description {
    if (node != null && node!.isNotEmpty) {
      if (nodeType == 'post' && node!['post_text'] != null) {
        return node!['post_text'] as String;
      }
      if (nodeType == 'comment' && node!['comment_text'] != null) {
        return node!['comment_text'] as String;
      }
    }
    return typeLabel;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'node_id': nodeId,
    'node_type': nodeType,
    'points': points,
    'time': time,
    'node': node,
  };
}
