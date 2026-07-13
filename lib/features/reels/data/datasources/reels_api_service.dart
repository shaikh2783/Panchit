import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/main.dart' show configCfgP;
import 'package:snginepro/features/reels/data/models/reels_response.dart';

class ReelsApiService {
  ReelsApiService(this._client);

  final ApiClient _client;

  Future<ReelsResponse> fetchReels({
    int limit = 10,
    int offset = 0,
    String source = 'all',
  }) async {
    final response = await _client.get(
      configCfgP('reels'),
      queryParameters: {
        'offset': '$offset',
        'limit': '$limit',
        'source': source,
      },
    );

    final reelsResponse = ReelsResponse.fromJson(response);
    if (!reelsResponse.isSuccess) {
      throw ApiException(
        'فشل في جلب الريلز',
        details: response,
      );
    }
    return reelsResponse;
  }

  /// All reels using [soundId] (docs/reels_backend_api.md §20). The endpoint
  /// is not implemented on the backend yet (docs/reels_backend_gaps.md gap 2)
  /// — callers must degrade gracefully when this throws.
  Future<ReelsBySoundResponse> fetchReelsBySound({
    required int soundId,
    int offset = 0,
    int limit = 18,
  }) async {
    final endpoint = configCfgP('reels_by_sound');
    if (endpoint.isEmpty) {
      throw ApiException('reels_by_sound endpoint not configured');
    }

    final response = await _client.get(
      endpoint,
      queryParameters: {
        'sound_id': '$soundId',
        'offset': '$offset',
        'limit': '$limit',
      },
    );

    final parsed = ReelsBySoundResponse.fromJson(response);
    if (!parsed.isSuccess) {
      throw ApiException(
        'Failed to fetch reels for sound $soundId',
        details: response,
      );
    }
    return parsed;
  }
}
