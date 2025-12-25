import 'package:meta/meta.dart';

@immutable
class ReviewPhoto {
  const ReviewPhoto({required this.photoId, required this.source});

  final int photoId;
  final String source;

  factory ReviewPhoto.fromJson(Map<String, dynamic> json) {
    return ReviewPhoto(
      photoId: _int(json['photo_id']),
      source: (json['source'] ?? '').toString(),
    );
  }

  static List<ReviewPhoto> listFromJson(Object? data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ReviewPhoto.fromJson)
          .toList();
    }
    return const [];
  }

  static int _int(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

@immutable
class PostReview {
  const PostReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userFirstName,
    required this.userLastName,
    required this.userPicture,
    required this.userVerified,
    required this.rate,
    required this.review,
    required this.time,
    required this.timeFormatted,
    required this.photos,
    required this.reply,
    required this.replyTime,
    required this.iOwn,
    required this.canReply,
  });

  final int id;
  final int userId;
  final String userName;
  final String userFirstName;
  final String userLastName;
  final String userPicture;
  final bool userVerified;
  final int rate;
  final String review;
  final String time;
  final String timeFormatted;
  final List<ReviewPhoto> photos;
  final String? reply;
  final String? replyTime;
  final bool iOwn;
  final bool canReply;

  factory PostReview.fromJson(Map<String, dynamic> json) {
    return PostReview(
      id: _int(json['review_id']),
      userId: _int(json['user_id']),
      userName: (json['user_name'] ?? '').toString(),
      userFirstName: (json['user_firstname'] ?? '').toString(),
      userLastName: (json['user_lastname'] ?? '').toString(),
      userPicture: (json['user_picture'] ?? '').toString(),
      userVerified: json['user_verified'] == true,
      rate: _int(json['rate']),
      review: (json['review'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      timeFormatted: (json['time_formatted'] ?? json['time'] ?? '').toString(),
      photos: ReviewPhoto.listFromJson(json['photos']),
      reply: (json['reply'] ?? json['reply_text'])?.toString(),
      replyTime: (json['reply_time'] ?? json['reply_date'])?.toString(),
      iOwn: json['i_own'] == true,
      canReply: json['can_reply'] == true,
    );
  }

  PostReview copyWith({
    String? reply,
    String? replyTime,
  }) {
    return PostReview(
      id: id,
      userId: userId,
      userName: userName,
      userFirstName: userFirstName,
      userLastName: userLastName,
      userPicture: userPicture,
      userVerified: userVerified,
      rate: rate,
      review: review,
      time: time,
      timeFormatted: timeFormatted,
      photos: photos,
      reply: reply ?? this.reply,
      replyTime: replyTime ?? this.replyTime,
      iOwn: iOwn,
      canReply: canReply,
    );
  }

  static int _int(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
