import '../data/models/funding.dart';
import '../data/services/funding_api_service.dart';
class FundingRepository {
  final FundingApiService _apiService;
  FundingRepository(this._apiService);
  Future<Map<String, dynamic>> getFunding({
    int offset = 0,
    int limit = 20,
    String search = '',
  }) async {
    return await _apiService.getFunding(
      offset: offset,
      limit: limit,
      search: search,
    );
  }
  Future<Funding> getFundingById(int id) async {
    return await _apiService.getFundingById(id);
  }
  Future<Funding> createFunding(Map<String, dynamic> body) async {
    return await _apiService.createFunding(body);
  }
  Future<Funding> updateFunding(int id, Map<String, dynamic> body) async {
    return await _apiService.updateFunding(id, body);
  }
  Future<void> deleteFunding(int id) async {
    return await _apiService.deleteFunding(id);
  }
  Future<Funding> donateFunding(int id, double amount) async {
    return await _apiService.donateFunding(id, amount);
  }
  Future<Map<String, dynamic>> getDonors(int id, {int offset = 0, int limit = 20}) async {
    return await _apiService.getDonors(id, offset: offset, limit: limit);
  }
}
