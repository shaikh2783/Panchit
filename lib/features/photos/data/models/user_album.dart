class UserAlbum {
  final String albumId;
  final String title;
  final int photosCount;
  final String? cover;
  final String privacy;
  final String createdAt;
  final bool manageAlbum;

  UserAlbum({
    required this.albumId,
    required this.title,
    required this.photosCount,
    this.cover,
    required this.privacy,
    required this.createdAt,
    required this.manageAlbum,
  });

  factory UserAlbum.fromJson(Map<String, dynamic> json) {
    final coverStr = json['cover']?.toString();
    return UserAlbum(
      albumId: json['album_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Album',
      photosCount: int.tryParse(json['photos_count']?.toString() ?? '0') ?? 0,
      cover: (coverStr != null && coverStr.isNotEmpty) ? coverStr : null,
      privacy: json['privacy']?.toString() ?? 'public',
      createdAt: json['created_at']?.toString() ?? '',
      manageAlbum: json['manage_album'] == true || json['manage_album'] == 1,
    );
  }
}
