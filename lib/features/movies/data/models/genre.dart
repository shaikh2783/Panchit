class Genre {
  final int genreId;
  final String genreName;
  final String? genreDescription;
  final int? genreOrder;
  final String? genreUrl;

  Genre({
    required this.genreId,
    required this.genreName,
    this.genreDescription,
    this.genreOrder,
    this.genreUrl,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Genre(
      genreId: _toInt(json['genre_id']),
      genreName: json['genre_name']?.toString() ?? '',
      genreDescription: json['genre_description']?.toString(),
      genreOrder: json['genre_order'] != null ? _toInt(json['genre_order']) : null,
      genreUrl: json['genre_url']?.toString(),
    );
  }
}
