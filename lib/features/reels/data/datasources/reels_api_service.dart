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
}
