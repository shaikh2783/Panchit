/// نماذج البيانات للبث المباشر
/// تستخدم مع LiveStreamApiService

/// نموذج بيانات البث المباشر
class LiveStreamModel {
  final String liveId;
  final String title;
  final String description;
  final String broadcasterName;
  final String broadcasterAvatar;
  final String? thumbnailUrl;
  final bool isVerified;
  final int viewersCount;
  final DateTime startTime;
  final String status; // live, ended, scheduled
  final String? category;
  final bool isPrivate;
  final String? agoraChannel;
  final String? agoraToken;

  const LiveStreamModel({
    required this.liveId,
    required this.title,
    required this.description,
    required this.broadcasterName,
    required this.broadcasterAvatar,
    this.thumbnailUrl,
    required this.isVerified,
    required this.viewersCount,
    required this.startTime,
    required this.status,
    this.category,
    required this.isPrivate,
    this.agoraChannel,
    this.agoraToken,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      liveId: json['live_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      broadcasterName: json['broadcaster_name']?.toString() ?? '',
      broadcasterAvatar: json['broadcaster_avatar']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      viewersCount: int.tryParse(json['viewers_count']?.toString() ?? '0') ?? 0,
      startTime: DateTime.tryParse(json['start_time']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'ended',
      category: json['category']?.toString(),
      isPrivate: json['is_private'] == true || json['is_private'] == 1,
      agoraChannel: json['agora_channel']?.toString(),
      agoraToken: json['agora_token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'live_id': liveId,
      'title': title,
      'description': description,
      'broadcaster_name': broadcasterName,
      'broadcaster_avatar': broadcasterAvatar,
      'thumbnail_url': thumbnailUrl,
      'is_verified': isVerified,
      'viewers_count': viewersCount,
      'start_time': startTime.toIso8601String(),
      'status': status,
      'category': category,
      'is_private': isPrivate,
      'agora_channel': agoraChannel,
      'agora_token': agoraToken,
    };
  }
}

/// نموذج تعليق البث المباشر
class LiveCommentModel {
  final String commentId;
  final String liveId;
  final String userId;
  final String userName;
  final String userAvatar;
  final bool isVerified;
  final String text;
  final String? imageUrl;
  final String? voiceUrl;
  final DateTime timestamp;
  final Map<String, int> reactions;
  final bool canEdit;
  final bool canDelete;

  const LiveCommentModel({
    required this.commentId,
    required this.liveId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.isVerified,
    required this.text,
    this.imageUrl,
    this.voiceUrl,
    required this.timestamp,
    required this.reactions,
    required this.canEdit,
    required this.canDelete,
  });

  factory LiveCommentModel.fromJson(Map<String, dynamic> json) {
    return LiveCommentModel(
      commentId: json['comment_id']?.toString() ?? '', // API يرسل string بالفعل
      liveId: json['node_id']?.toString() ?? '', // node_id في API response
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['name']?.toString() ?? '',
      userAvatar: json['user_avatar']?.toString() ?? json['avatar']?.toString() ?? '',
      isVerified: json['is_verified'] == true || json['is_verified'] == 1 || json['verified'] == true || json['verified'] == 1,
      text: json['text']?.toString() ?? '',
      imageUrl: json['image']?.toString().isEmpty == true ? null : json['image']?.toString(),
      voiceUrl: json['voice_note']?.toString().isEmpty == true ? null : json['voice_note']?.toString(),
      timestamp: DateTime.tryParse(json['time']?.toString() ?? '') ?? 
                 DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? 
                 DateTime.now(),
      reactions: _parseReactions(json['reactions']),
      canEdit: json['can_edit'] == true || json['can_edit'] == 1,
      canDelete: json['can_delete'] == true || json['can_delete'] == 1,
    );
  }

  static Map<String, int> _parseReactions(dynamic reactions) {
    if (reactions == null) {
      return {
        'like': 0,
        'love': 0,
        'haha': 0,
        'wow': 0,
        'sad': 0,
        'angry': 0,
      };
    }

    if (reactions is Map) {
      final Map<String, int> result = {};
      reactions.forEach((key, value) {
        result[key.toString()] = int.tryParse(value.toString()) ?? 0;
      });
      return result;
    }

    return {
      'like': 0,
      'love': 0,
      'haha': 0,
      'wow': 0,
      'sad': 0,
      'angry': 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'live_id': liveId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'is_verified': isVerified,
      'text': text,
      'image_url': imageUrl,
      'voice_url': voiceUrl,
      'timestamp': timestamp.toIso8601String(),
      'reactions': reactions,
      'can_edit': canEdit,
      'can_delete': canDelete,
    };
  }
}

/// نموذج إحصائيات البث المباشر
class LiveStatsModel {
  final String liveId;
  final int totalViewers;
  final int currentViewers;
  final int totalComments;
  final int totalReactions;
  final Duration duration;
  final Map<String, int> reactionsCounts;
  final DateTime lastUpdate;

  const LiveStatsModel({
    required this.liveId,
    required this.totalViewers,
    required this.currentViewers,
    required this.totalComments,
    required this.totalReactions,
    required this.duration,
    required this.reactionsCounts,
    required this.lastUpdate,
  });

  factory LiveStatsModel.fromJson(Map<String, dynamic> json) {
    // حساب عدد التعليقات بشكل آمن
    int commentsCount = 0;
    final comments = json['comments'];
    if (comments is List) {
      commentsCount = comments.length;
    }
    
    return LiveStatsModel(
      liveId: json['live_id']?.toString() ?? '',
      totalViewers: int.tryParse(json['total_viewers']?.toString() ?? '0') ?? 0,
      currentViewers: int.tryParse(json['live_count']?.toString() ?? '0') ?? 0, // live_count من API
      totalComments: commentsCount, // عدد التعليقات المحسوب بأمان
      totalReactions: int.tryParse(json['total_reactions']?.toString() ?? '0') ?? 0,
      duration: Duration(
        seconds: int.tryParse(json['duration_seconds']?.toString() ?? '0') ?? 0,
      ),
      reactionsCounts: _parseReactionsCounts(json['reactions_counts']),
      lastUpdate: DateTime.now(), // استخدام الوقت الحالي
    );
  }

  static Map<String, int> _parseReactionsCounts(dynamic reactions) {
    if (reactions == null) {
      return {
        'like': 0,
        'love': 0,
        'haha': 0,
        'wow': 0,
        'sad': 0,
        'angry': 0,
      };
    }

    if (reactions is Map) {
      final Map<String, int> result = {};
      reactions.forEach((key, value) {
        result[key.toString()] = int.tryParse(value.toString()) ?? 0;
      });
      return result;
    }

    return {
      'like': 0,
      'love': 0,
      'haha': 0,
      'wow': 0,
      'sad': 0,
      'angry': 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'live_id': liveId,
      'total_viewers': totalViewers,
      'current_viewers': currentViewers,
      'total_comments': totalComments,
      'total_reactions': totalReactions,
      'duration_seconds': duration.inSeconds,
      'reactions_counts': reactionsCounts,
      'last_update': lastUpdate.toIso8601String(),
    };
  }
}

/// نموذج استجابة API للتعليقات
class LiveCommentsResponse {
  final bool success;
  final String message;
  final List<LiveCommentModel> comments;
  final LiveCommentsMetadata metadata;

  const LiveCommentsResponse({
    required this.success,
    required this.message,
    required this.comments,
    required this.metadata,
  });

  factory LiveCommentsResponse.fromJson(Map<String, dynamic> json) {
    // جلب التعليقات بشكل آمن
    List<LiveCommentModel> commentsList = [];
    final commentsData = json['data']?['comments'];
    
    if (commentsData is List) {
      commentsList = commentsData
          .map((commentJson) => LiveCommentModel.fromJson(commentJson))
          .toList();
    }
    
    return LiveCommentsResponse(
      success: json['status'] == 'success',
      message: json['message']?.toString() ?? '',
      comments: commentsList,
      metadata: LiveCommentsMetadata(
        currentPage: 1,
        totalPages: 1,
        totalComments: commentsList.length,
        limit: 20,
        hasMore: false,
        nextPageToken: null,
      ),
    );
  }
}

/// بيانات وصفية للتعليقات
class LiveCommentsMetadata {
  final int currentPage;
  final int totalPages;
  final int totalComments;
  final int limit;
  final bool hasMore;
  final String? nextPageToken;

  const LiveCommentsMetadata({
    required this.currentPage,
    required this.totalPages,
    required this.totalComments,
    required this.limit,
    required this.hasMore,
    this.nextPageToken,
  });

  factory LiveCommentsMetadata.fromJson(Map<String, dynamic> json) {
    return LiveCommentsMetadata(
      currentPage: int.tryParse(json['current_page']?.toString() ?? '1') ?? 1,
      totalPages: int.tryParse(json['total_pages']?.toString() ?? '1') ?? 1,
      totalComments: int.tryParse(json['total_comments']?.toString() ?? '0') ?? 0,
      limit: int.tryParse(json['limit']?.toString() ?? '20') ?? 20,
      hasMore: json['has_more'] == true,
      nextPageToken: json['next_page_token']?.toString(),
    );
  }
}

/// نموذج التفاعل المباشر
class LiveReactionModel {
  final String reactionId;
  final String liveId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String reactionType;
  final DateTime timestamp;

  const LiveReactionModel({
    required this.reactionId,
    required this.liveId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.reactionType,
    required this.timestamp,
  });

  factory LiveReactionModel.fromJson(Map<String, dynamic> json) {
    return LiveReactionModel(
      reactionId: json['reaction_id']?.toString() ?? '',
      liveId: json['live_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userAvatar: json['user_avatar']?.toString() ?? '',
      reactionType: json['reaction_type']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}