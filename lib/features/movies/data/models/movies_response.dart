import 'movie.dart';

class MoviesResponse {
  final List<Movie> movies;
  final bool hasMore;
  final int limit;
  final int offset;

  MoviesResponse({
    required this.movies,
    required this.hasMore,
    required this.limit,
    required this.offset,
  });
}
