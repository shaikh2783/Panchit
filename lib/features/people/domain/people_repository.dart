import '../data/services/people_api_service.dart';
import '../data/models/people_response.dart';

class PeopleRepository {
  PeopleRepository(this._api);

  final PeopleApiService _api;

  Future<PeopleResponse> fetchPeople({int offset = 0, bool random = false}) {
    return _api.fetchPeople(offset: offset, random: random);
  }
}
