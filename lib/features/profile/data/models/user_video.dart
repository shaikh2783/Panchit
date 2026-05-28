class UserVideo {
  final int videoId;
  final int postId;
  final String videoUrl;
  final String? videoThumb;
  final int videoDuration;
  final String privacy;

  UserVideo({
    required this.videoId,
    required this.postId,
    required this.videoUrl,
    this.videoThumb,
    required this.videoDuration,
    required this.privacy,
  });

  factory UserVideo.fromJson(Map<String, dynamic> json) {
    return UserVideo(
      videoId: json['video_id'] ?? 0,
      postId: json['post_id'] ?? 0,
      videoUrl: json['video_url'] ?? '',
      videoThumb: json['video_thumb'],
      videoDuration: json['video_duration'] ?? 0,
      privacy: json['privacy'] ?? 'public',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_id': videoId,
      'post_id': postId,
      'video_url': videoUrl,
      'video_thumb': videoThumb,
      'video_duration': videoDuration,
      'privacy': privacy,
    };
  }
}
