import 'genre.dart';

class Movie {
  final int movieId;
  final String title;
  final String? description;
  final String? stars;
  final String? poster;
  final String? movieUrl;
  final String? genres;
  final List<Genre> genresList;
  final int isPaid;
  final int availableFor;
  final int views;
  final bool? canWatch;
  final String? source;
  final String? sourceType;

  Movie({
    required this.movieId,
    required this.title,
    this.description,
    this.stars,
    this.poster,
    this.movieUrl,
    this.genres,
    this.genresList = const [],
    this.isPaid = 0,
    this.availableFor = 0,
    this.views = 0,
    this.canWatch,
    this.source,
    this.sourceType,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool? _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
      }
      return null;
    }

    final genresRaw = json['genres_list'];
    final genresList = (genresRaw is List)
        ? genresRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => Genre.fromJson(e))
            .toList()
        : <Genre>[];

    return Movie(
      movieId: _toInt(json['movie_id']),
      title: json['title']?.toString() ?? '',
      description: (json['description'] ?? json['desc'])?.toString(),
      stars: json['stars']?.toString(),
      poster: json['poster']?.toString(),
      movieUrl: json['movie_url']?.toString(),
      genres: json['genres']?.toString(),
      genresList: genresList,
      isPaid: json['is_paid'] != null ? _toInt(json['is_paid']) : 0,
      availableFor: json['available_for'] != null ? _toInt(json['available_for']) : 0,
      views: json['views'] != null ? _toInt(json['views']) : 0,
      canWatch: _toBool(json['can_watch']),
      source: json['source']?.toString(),
      sourceType: json['source_type']?.toString(),
    );
  }
}
