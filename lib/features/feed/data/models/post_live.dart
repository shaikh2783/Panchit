class PostLive {
  final String liveId;
  final String postId;
  final String? videoThumbnail;
  final String agoraUid;
  final String agoraChannelName;
  final String? agoraResourceId;
  final String? agoraSid;
  final String? agoraFile;
  final bool liveEnded;
  final bool liveRecorded;
  final String? agoraAudienceUid;
  final String? agoraAudienceToken;

  const PostLive({
    required this.liveId,
    required this.postId,
    this.videoThumbnail,
    required this.agoraUid,
    required this.agoraChannelName,
    this.agoraResourceId,
    this.agoraSid,
    this.agoraFile,
    required this.liveEnded,
    required this.liveRecorded,
    this.agoraAudienceUid,
    this.agoraAudienceToken,
  });

  bool get isActive => !liveEnded;
  
  factory PostLive.fromJson(Map<String, dynamic> json) {
    return PostLive(
      liveId: json['live_id'].toString(),
      postId: json['post_id'].toString(),
      videoThumbnail: json['video_thumbnail'],
      agoraUid: json['agora_uid'].toString(),
      agoraChannelName: json['agora_channel_name'].toString(),
      agoraResourceId: json['agora_resource_id'],
      agoraSid: json['agora_sid'],
      agoraFile: json['agora_file'],
      liveEnded: json['live_ended'] == "1",
      liveRecorded: json['live_recorded'] == "1",
      agoraAudienceUid: json['agora_audience_uid']?.toString(),
      agoraAudienceToken: json['agora_audience_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'live_id': liveId,
      'post_id': postId,
      'video_thumbnail': videoThumbnail,
      'agora_uid': agoraUid,
      'agora_channel_name': agoraChannelName,
      'agora_resource_id': agoraResourceId,
      'agora_sid': agoraSid,
      'agora_file': agoraFile,
      'live_ended': liveEnded ? "1" : "0",
      'live_recorded': liveRecorded ? "1" : "0",
      'agora_audience_uid': agoraAudienceUid,
      'agora_audience_token': agoraAudienceToken,
    };
  }

  PostLive copyWith({
    String? liveId,
    String? postId,
    String? videoThumbnail,
    String? agoraUid,
    String? agoraChannelName,
    String? agoraResourceId,
    String? agoraSid,
    String? agoraFile,
    bool? liveEnded,
    bool? liveRecorded,
    String? agoraAudienceUid,
    String? agoraAudienceToken,
  }) {
    return PostLive(
      liveId: liveId ?? this.liveId,
      postId: postId ?? this.postId,
      videoThumbnail: videoThumbnail ?? this.videoThumbnail,
      agoraUid: agoraUid ?? this.agoraUid,
      agoraChannelName: agoraChannelName ?? this.agoraChannelName,
      agoraResourceId: agoraResourceId ?? this.agoraResourceId,
      agoraSid: agoraSid ?? this.agoraSid,
      agoraFile: agoraFile ?? this.agoraFile,
      liveEnded: liveEnded ?? this.liveEnded,
      liveRecorded: liveRecorded ?? this.liveRecorded,
      agoraAudienceUid: agoraAudienceUid ?? this.agoraAudienceUid,
      agoraAudienceToken: agoraAudienceToken ?? this.agoraAudienceToken,
    );
  }

  @override
  String toString() {
    return 'PostLive(liveId: $liveId, channelName: $agoraChannelName, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostLive &&
        other.liveId == liveId &&
        other.agoraChannelName == agoraChannelName;
  }

  @override
  int get hashCode {
    return liveId.hashCode ^ agoraChannelName.hashCode;
  }
}