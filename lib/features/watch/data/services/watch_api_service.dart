import 'package:snginepro/core/network/api_client.dart';
import '../models/watch_response.dart';

class WatchApiService {
  WatchApiService(this._client);

  final ApiClient _client;

  Future<WatchResponse> fetchWatch({int offset = 0, int limit = 20, String? country}) async {
    final response = await _client.get(
      '/data/watch',
      queryParameters: {
        'offset': offset.toString(),
        'limit': limit.toString(),
        if (country != null && country.isNotEmpty) 'country': country,
      },
    );

    return WatchResponse.fromJson(response);
  }
}
