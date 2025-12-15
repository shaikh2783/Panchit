class CommentModel {
  final String commentId;
  final String nodeId;
  final String nodeType;
  final String userId;
  final String text;
  final String? image;
  final String? voiceNote;
  final String time;
  final int repliesCount;
  final String authorId;
  final String authorName;
  final String authorFirstname;
  final String authorLastname;
  final String authorPicture;
  final bool authorVerified;
  final Map<String, int> reactions;
  final int reactionsTotalCount;
  final bool iReact;
  final String? iReaction;
  final bool canEdit;
  final bool canDelete;
  final String textPlain;
  CommentModel({
    required this.commentId,
    required this.nodeId,
    required this.nodeType,
    required this.userId,
    required this.text,
    this.image,
    this.voiceNote,
    required this.time,
    required this.repliesCount,
    required this.authorId,
    required this.authorName,
    required this.authorFirstname,
    required this.authorLastname,
    required this.authorPicture,
    required this.authorVerified,
    required this.reactions,
    required this.reactionsTotalCount,
    required this.iReact,
    this.iReaction,
    required this.canEdit,
    required this.canDelete,
    required this.textPlain,
  });
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['comment_id']?.toString() ?? '',
      nodeId: json['node_id']?.toString() ?? '',
      nodeType: json['node_type']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      image: json['image']?.toString().isEmpty == true 
          ? null 
          : json['image']?.toString(),
      voiceNote: json['voice_note']?.toString().isEmpty == true 
          ? null 
          : json['voice_note']?.toString(),
      time: json['time']?.toString() ?? '',
      repliesCount: int.tryParse(json['replies']?.toString() ?? '0') ?? 0,
      authorId: json['author_id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? '',
      authorFirstname: json['author_firstname']?.toString() ?? '',
      authorLastname: json['author_lastname']?.toString() ?? '',
      authorPicture: json['author_picture']?.toString() ?? '',
      authorVerified: json['author_verified'] == true || 
                      json['author_verified'] == 1 ||
                      json['author_verified']?.toString() == '1',
      reactions: _parseReactions(json['reactions']),
      reactionsTotalCount: json['reactions_total_count'] is int
          ? json['reactions_total_count']
          : int.tryParse(json['reactions_total_count']?.toString() ?? '0') ?? 0,
      iReact: json['i_react'] == true || 
              json['i_react'] == 1 ||
              json['i_react']?.toString() == '1',
      iReaction: json['i_reaction']?.toString().isEmpty == true 
          ? null 
          : json['i_reaction']?.toString(),
      canEdit: json['edit_comment'] == true || 
               json['edit_comment'] == 1 ||
               json['edit_comment']?.toString() == '1',
      canDelete: json['delete_comment'] == true || 
                 json['delete_comment'] == 1 ||
                 json['delete_comment']?.toString() == '1',
      textPlain: json['text_plain']?.toString() ?? json['text']?.toString() ?? '',
    );
  }
  static Map<String, int> _parseReactions(dynamic reactions) {
    if (reactions == null) {
      return {
        'like': 0,
        'love': 0,
        'haha': 0,
        'yay': 0,
        'wow': 0,
        'sad': 0,
        'angry': 0,
      };
    }
    final Map<String, dynamic> reactionsMap = reactions is Map 
        ? Map<String, dynamic>.from(reactions)
        : {};
    return {
      'like': int.tryParse(reactionsMap['like']?.toString() ?? '0') ?? 0,
      'love': int.tryParse(reactionsMap['love']?.toString() ?? '0') ?? 0,
      'haha': int.tryParse(reactionsMap['haha']?.toString() ?? '0') ?? 0,
      'yay': int.tryParse(reactionsMap['yay']?.toString() ?? '0') ?? 0,
      'wow': int.tryParse(reactionsMap['wow']?.toString() ?? '0') ?? 0,
      'sad': int.tryParse(reactionsMap['sad']?.toString() ?? '0') ?? 0,
      'angry': int.tryParse(reactionsMap['angry']?.toString() ?? '0') ?? 0,
    };
  }
  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'node_id': nodeId,
      'node_type': nodeType,
      'user_id': userId,
      'text': text,
      'image': image ?? '',
      'voice_note': voiceNote ?? '',
      'time': time,
      'replies': repliesCount.toString(),
      'author_id': authorId,
      'author_name': authorName,
      'author_firstname': authorFirstname,
      'author_lastname': authorLastname,
      'author_picture': authorPicture,
      'author_verified': authorVerified,
      'reactions': reactions,
      'reactions_total_count': reactionsTotalCount,
      'i_react': iReact,
      'i_reaction': iReaction,
      'edit_comment': canEdit,
      'delete_comment': canDelete,
      'text_plain': textPlain,
    };
  }
  CommentModel copyWith({
    String? commentId,
    String? nodeId,
    String? nodeType,
    String? userId,
    String? text,
    String? image,
    String? voiceNote,
    String? time,
    int? repliesCount,
    String? authorId,
    String? authorName,
    String? authorFirstname,
    String? authorLastname,
    String? authorPicture,
    bool? authorVerified,
    Map<String, int>? reactions,
    int? reactionsTotalCount,
    bool? iReact,
    String? iReaction,
    bool? canEdit,
    bool? canDelete,
    String? textPlain,
  }) {
    return CommentModel(
      commentId: commentId ?? this.commentId,
      nodeId: nodeId ?? this.nodeId,
      nodeType: nodeType ?? this.nodeType,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      image: image ?? this.image,
      voiceNote: voiceNote ?? this.voiceNote,
      time: time ?? this.time,
      repliesCount: repliesCount ?? this.repliesCount,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorFirstname: authorFirstname ?? this.authorFirstname,
      authorLastname: authorLastname ?? this.authorLastname,
      authorPicture: authorPicture ?? this.authorPicture,
      authorVerified: authorVerified ?? this.authorVerified,
      reactions: reactions ?? this.reactions,
      reactionsTotalCount: reactionsTotalCount ?? this.reactionsTotalCount,
      iReact: iReact ?? this.iReact,
      iReaction: iReaction ?? this.iReaction,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      textPlain: textPlain ?? this.textPlain,
    );
  }
}
