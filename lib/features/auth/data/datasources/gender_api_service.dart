import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/auth/data/models/gender.dart';

class GenderApiService {
  final ApiClient _client;

  GenderApiService(this._client);

  Future<List<Gender>> getGenders() async {

    final response = await _client.get('/app/genders');
    
    if (response['status'] == 'success' && response['data'] is List) {
      final List<dynamic> data = response['data'];
      final genders = data.map((json) => Gender.fromJson(json)).toList();

      return genders;
    }

    return [];
  }
}
