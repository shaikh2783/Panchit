import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/funding.dart';
class FundingApiService {
  final ApiClient _client;
  FundingApiService(this._client);
  /// Get list of funding requests
  Future<Map<String, dynamic>> getFunding({
    int offset = 0,
    int limit = 20,
    String search = '',
  }) async {
    final query = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search.isNotEmpty) 'search': search,
    };
    return await _client.get(configCfgP('funding_base'), queryParameters: query);
  }
  /// Get single funding request
  Future<Funding> getFundingById(int id) async {
    final response = await _client.get('${configCfgP('funding_base')}/$id');
    if (response['status'] == 'success' && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return Funding.fromJson(data['funding'] ?? data);
    }
    throw Exception(response['message'] ?? 'Failed to fetch funding');
  }
  /// Create funding request
  Future<Funding> createFunding(Map<String, dynamic> body) async {
    final response = await _client.post(configCfgP('funding_base'), body: body);
    if (response['status'] == 'success' && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return Funding.fromJson(data['funding'] ?? data);
    }
    throw Exception(response['message'] ?? 'Failed to create funding');
  }
  /// Update funding request
  Future<Funding> updateFunding(int id, Map<String, dynamic> body) async {
    final response = await _client.post('${configCfgP('funding_base')}/$id/update', body: body);
    if (response['status'] == 'success' && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return Funding.fromJson(data['funding'] ?? data);
    }
    throw Exception(response['message'] ?? 'Failed to update funding');
  }
  /// Delete funding request
  Future<void> deleteFunding(int id) async {
    final response = await _client.post('${configCfgP('funding_base')}/$id/delete');
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to delete funding');
    }
  }
  /// Donate to funding request
  Future<Funding> donateFunding(int id, double amount) async {
    final response = await _client.post(
      '${configCfgP('funding_base')}/$id/donate',
      body: {'amount': amount},
    );
    if (response['status'] == 'success' && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return Funding.fromJson(data['funding'] ?? data);
    }
    throw Exception(response['message'] ?? 'Failed to donate');
  }
  /// Get donors list
  Future<Map<String, dynamic>> getDonors(int id, {int offset = 0, int limit = 20}) async {
    final query = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
    };
    return await _client.get('${configCfgP('funding_base')}/$id/donors', queryParameters: query);
  }
}
