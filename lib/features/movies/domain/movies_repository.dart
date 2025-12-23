import '../data/services/movies_api_service.dart';
import '../data/models/movie.dart';
import '../data/models/genre.dart';
import '../data/models/movies_response.dart';

class MoviesRepository {
  final MoviesApiService _service;
  MoviesRepository(this._service);

  Future<MoviesResponse> listMovies({
    String? query,
    int? genreId,
    int offset = 0,
    int limit = 12,
  }) => _service.listMovies(query: query, genreId: genreId, offset: offset, limit: limit);

  Future<List<Genre>> getGenres() => _service.getGenres();
  Future<Movie> getMovie(int id) => _service.getMovie(id);
  Future<String> purchaseMovie(int id) => _service.purchaseMovie(id);
}
