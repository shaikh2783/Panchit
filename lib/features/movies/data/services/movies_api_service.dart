import 'package:snginepro/core/network/api_client.dart';

import '../../data/models/movie.dart';
import '../../data/models/genre.dart';
import '../../data/models/movies_response.dart';

class MoviesApiService {
  final ApiClient _client;
  MoviesApiService(this._client);

  Future<MoviesResponse> listMovies({
    String? query,
    int? genreId,
    int offset = 0,
    int limit = 12,
  }) async {
    final params = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
    };
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (genreId != null && genreId > 0) params['genre_id'] = genreId.toString();

    final res = await _client.get('/data/movies', queryParameters: params);
    final data = (res['data'] as List<dynamic>? ?? []);
    final movies = data.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
    final hasMore = res['has_more'] == true || res['has_more'] == 1;
    final newLimit = (res['limit'] as num?)?.toInt() ?? limit;
    final newOffset = (res['offset'] as num?)?.toInt() ?? offset;
    return MoviesResponse(movies: movies, hasMore: hasMore, limit: newLimit, offset: newOffset);
  }

  Future<List<Genre>> getGenres() async {
    final res = await _client.get('/data/movies/genres');
    final list = (res['data'] as List<dynamic>? ?? []);
    return list.map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Movie> getMovie(int id) async {
    final res = await _client.get('/data/movies/$id');
    final map = (res['data'] as Map<String, dynamic>? ?? {});
    return Movie.fromJson(map);
  }

  Future<String> purchaseMovie(int id) async {
    final res = await _client.post('/data/movies/$id/purchase');
    final data = res['data'] as Map<String, dynamic>?;
    final url = data?['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('No purchase URL returned');
    }
    return url;
  }
}
