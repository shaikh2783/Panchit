import 'package:snginepro/core/network/api_client.dart';
import '../models/person.dart';
import '../models/people_response.dart';

class PeopleApiService {
  PeopleApiService(this._client);

  final ApiClient _client;

  Future<PeopleResponse> fetchPeople({int offset = 0, bool random = false}) async {
    final response = await _client.get(
      '/data/people',
      queryParameters: {
        'offset': offset.toString(),
        'random': random ? 'true' : 'false',
      },
    );

    return PeopleResponse.fromJson(response);
  }
}
