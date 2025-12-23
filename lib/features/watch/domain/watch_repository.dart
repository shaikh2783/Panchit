import '../data/services/watch_api_service.dart';
import '../data/models/watch_response.dart';

class WatchRepository {
  WatchRepository(this._api);
  final WatchApiService _api;

  Future<WatchResponse> fetchWatch({int offset = 0, int limit = 20, String? country}) {
    return _api.fetchWatch(offset: offset, limit: limit, country: country);
  }
}
