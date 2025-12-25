import 'package:snginepro/features/reels/data/datasources/reels_api_service.dart';
import 'package:snginepro/features/reels/data/models/reels_response.dart';

class ReelsRepository {
  ReelsRepository(this._apiService);

  final ReelsApiService _apiService;

  Future<ReelsResponse> fetchReels({
    int limit = 10,
    int offset = 0,
    String source = 'all',
  }) {
    return _apiService.fetchReels(
      limit: limit,
      offset: offset,
      source: source,
    );
  }
}

