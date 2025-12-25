class UserPhoto {
  final String photoId;
  final String source;
  final String blur;
  final bool pinned;
  final String privacy;
  final bool manage;

  UserPhoto({
    required this.photoId,
    required this.source,
    required this.blur,
    required this.pinned,
    required this.privacy,
    required this.manage,
  });

  factory UserPhoto.fromJson(Map<String, dynamic> json) {
    return UserPhoto(
      photoId: json['photo_id']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      blur: json['blur']?.toString() ?? '0',
      pinned: json['pinned'] == true || json['pinned'] == 1,
      privacy: json['privacy']?.toString() ?? 'public',
      manage: json['manage'] == true || json['manage'] == 1,
    );
  }

  bool get isBlurred => blur == '1';
}
